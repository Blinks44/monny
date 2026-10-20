import Foundation
import Darwin

/// Checkpoint I/O owned by one serialized transaction. No default or global storage location.
nonisolated struct NativeChargeLimitJournal: Sendable {
    var load: @Sendable () throws -> Data?
    var save: @Sendable (Data) throws -> Void
    var clear: @Sendable () throws -> Void
}

/// Atomic process-restart checkpoints in an existing private directory owned by this effective uid.
/// Production must supply a trusted fixed directory; concurrent transaction owners are unsupported.
nonisolated final class NativeChargeLimitFileJournal: Sendable {
    private let directory: Int32
    private static let filename = "native-charge-recovery.json"

    /// Fixed production location; only the privileged helper may create/open it.
    /// Preparation only: the shipped helper never calls this factory.
    static func systemJournal() throws -> NativeChargeLimitFileJournal {
        guard geteuid() == 0 else { throw POSIXError(.EPERM) }
        return try inTrustedRoot(URL(fileURLWithPath: "/", isDirectory: true), owner: 0)
    }

    /// Allows isolated fixtures to reproduce the same traversal in a private temporary root.
    /// The root and its ancestors must be trusted; no path may originate from IPC.
    static func inTrustedRoot(_ root: URL, owner: uid_t) throws -> NativeChargeLimitFileJournal {
        var current = open(root.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard current >= 0 else { throw posixError() }
        defer { close(current) }
        try validateDirectory(current, owner: owner, privateAccess: false)
        for component in ["Library", "Application Support", "Monny"] {
            if component == "Monny" {
                if mkdirat(current, component, 0o700) != 0, errno != EEXIST { throw posixError() }
            }
            let next = openat(current, component, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
            guard next >= 0 else { throw posixError() }
            do { try validateDirectory(next, owner: owner, privateAccess: component == "Monny") }
            catch { close(next); throw error }
            close(current)
            current = next
        }
        guard fsync(current) == 0 else { throw posixError() }
        // Duplicate ownership so the traversal's deferred close cannot invalidate the journal.
        let owned = fcntl(current, F_DUPFD_CLOEXEC, 0)
        guard owned >= 0 else { throw posixError() }
        return NativeChargeLimitFileJournal(directoryDescriptor: owned)
    }

    private init(directoryDescriptor: Int32) { directory = directoryDescriptor }

    private static func validateDirectory(_ descriptor: Int32, owner: uid_t, privateAccess: Bool) throws {
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0,
              metadata.st_uid == owner, metadata.st_mode & (privateAccess ? 0o077 : 0o022) == 0 else {
            throw POSIXError(.EACCES)
        }
    }

    init(privateDirectory: URL) throws {
        let descriptor = open(privateDirectory.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else { throw Self.posixError() }
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0,
              metadata.st_uid == geteuid(), metadata.st_mode & 0o077 == 0 else {
            close(descriptor)
            throw POSIXError(.EACCES)
        }
        directory = descriptor
    }

    deinit { close(directory) }

    var journal: NativeChargeLimitJournal {
        .init(load: { try self.load() }, save: { try self.save($0) }, clear: { try self.clear() })
    }

    private func load() throws -> Data? {
        let descriptor = openat(directory, Self.filename, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        guard descriptor >= 0 else {
            if errno == ENOENT { return nil }
            throw Self.posixError()
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        var metadata = stat()
        guard fstat(descriptor, &metadata) == 0,
              metadata.st_mode & S_IFMT == S_IFREG, metadata.st_nlink == 1,
              metadata.st_uid == geteuid(), metadata.st_mode & 0o077 == 0,
              metadata.st_size > 0, metadata.st_size <= 4096 else { throw POSIXError(.EINVAL) }
        let data = try handle.read(upToCount: 4097) ?? Data()
        guard data.count == metadata.st_size else { throw POSIXError(.EINVAL) }
        return data
    }

    private func save(_ data: Data) throws {
        guard !data.isEmpty, data.count <= 4096 else { throw POSIXError(.EINVAL) }
        let temporary = ".native-charge-\(UUID().uuidString).tmp"
        let descriptor = openat(directory, temporary, O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW | O_CLOEXEC, 0o600)
        guard descriptor >= 0 else { throw Self.posixError() }
        defer { unlinkat(directory, temporary, 0) }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        try handle.write(contentsOf: data)
        try handle.synchronize()
        guard renameat(directory, temporary, directory, Self.filename) == 0 else { throw Self.posixError() }
        guard fsync(directory) == 0 else { throw Self.posixError() }
    }

    private func clear() throws {
        if unlinkat(directory, Self.filename, 0) != 0, errno != ENOENT { throw Self.posixError() }
        guard fsync(directory) == 0 else { throw Self.posixError() }
    }

    private static func posixError() -> POSIXError { POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
}
