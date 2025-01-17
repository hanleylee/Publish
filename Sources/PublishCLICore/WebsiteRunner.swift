/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import Files
import ShellOut

internal struct WebsiteRunner {
    let folder: Folder
    var portNumber: Int

    func run() throws {
        let outputFolder = try resolveOutputFolder()

        let serverQueue = DispatchQueue(label: "Publish.WebServer")
        let serverProcess = Process()

        print("""
        🌍 Starting web server at http://localhost:\(portNumber)

        Press ENTER or CONTROL+C to stop the server and exit
        """)


        // Handle Ctrl+C shutdown
        let signalsQueue = DispatchQueue(label: "Publish.signals")

        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalsQueue)
        sigintSrc.setEventHandler {
            serverProcess.terminate()
            exit(0)
        }

        sigintSrc.resume()

        signal(SIGINT, SIG_IGN) // Make sure the signal does not terminate the application.

        serverQueue.async {
            do {
                _ = try shellOut(
                    to: "python3 -m http.server \(self.portNumber)",
                    at: outputFolder.path,
                    process: serverProcess
                )
            } catch let error as ShellOutError {
                self.outputServerErrorMessage(error.message)
            } catch {
                self.outputServerErrorMessage(error.localizedDescription)
            }

            serverProcess.terminate()
            exit(1)
        }

        _ = readLine()
        serverProcess.terminate()
    }
}

private extension WebsiteRunner {
    func resolveOutputFolder() throws -> Folder {
        do { return try folder.subfolder(named: "Output") }
        catch { throw CLIError.outputFolderNotFound }
    }

    func outputServerErrorMessage(_ message: String) {
        var message = message

        if message.hasPrefix("Traceback"),
           message.contains("Address already in use") {
            message = """
            A localhost server is already running on port number \(portNumber).
            - Perhaps another 'publish run' session is running?
            - Publish uses Python's simple HTTP server, so to find any
              running processes, you can use either Activity Monitor
              or the 'ps' command and search for 'python'. You can then
              terminate any previous process in order to start a new one.
            """
        }

        fputs("\n❌ Failed to start local web server:\n\(message)\n", stderr)
    }
}
