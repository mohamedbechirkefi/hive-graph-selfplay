//! UHP client: drive another UHP engine (Mzinga, nokamute, or ourselves) as
//! a subprocess. Used for differential fuzzing and arena matches.

use std::io::{BufRead, BufReader, Write};
use std::process::{Child, ChildStdin, ChildStdout, Command, Stdio};

pub struct UhpClient {
    child: Child,
    stdin: ChildStdin,
    stdout: BufReader<ChildStdout>,
    pub startup: Vec<String>,
}

impl UhpClient {
    /// Spawn `program args...` and consume its startup info block.
    pub fn spawn(program: &str, args: &[&str]) -> std::io::Result<UhpClient> {
        let mut child = Command::new(program)
            .args(args)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn()?;
        let stdin = child.stdin.take().unwrap();
        let stdout = BufReader::new(child.stdout.take().unwrap());
        let mut client = UhpClient {
            child,
            stdin,
            stdout,
            startup: Vec::new(),
        };
        client.startup = client.read_block()?;
        Ok(client)
    }

    /// Read lines until the `ok` terminator; returns the block without it.
    fn read_block(&mut self) -> std::io::Result<Vec<String>> {
        let mut lines = Vec::new();
        loop {
            let mut line = String::new();
            let n = self.stdout.read_line(&mut line)?;
            if n == 0 {
                return Err(std::io::Error::new(
                    std::io::ErrorKind::UnexpectedEof,
                    format!("engine died; partial block: {lines:?}"),
                ));
            }
            let line = line.trim_end().to_string();
            if line == "ok" {
                return Ok(lines);
            }
            lines.push(line);
        }
    }

    /// Send a command and collect its response block.
    pub fn command(&mut self, cmd: &str) -> std::io::Result<Vec<String>> {
        writeln!(self.stdin, "{cmd}")?;
        self.stdin.flush()?;
        self.read_block()
    }

    /// `validmoves` as a set of MoveStrings.
    pub fn valid_moves(&mut self) -> std::io::Result<Vec<String>> {
        let block = self.command("validmoves")?;
        let line = block.first().cloned().unwrap_or_default();
        if line.starts_with("err") || line.is_empty() {
            return Ok(Vec::new());
        }
        Ok(line.split(';').map(|s| s.trim().to_string()).collect())
    }
}

impl Drop for UhpClient {
    fn drop(&mut self) {
        let _ = writeln!(self.stdin, "exit");
        let _ = self.stdin.flush();
        let _ = self.child.wait();
    }
}
