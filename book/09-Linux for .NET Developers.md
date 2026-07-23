# Linux for .NET Developers

## Chapter Purpose

Modern .NET is cross-platform, which means a .NET developer can no longer
assume that production is always Windows Server and IIS.

That does not mean you must become a full-time Linux administrator. This
chapter has a narrower goal: give an experienced Windows and .NET developer
enough Linux fluency to understand where modern .NET applications run, how to
navigate a Linux environment, how processes and permissions work, how basic
networking is inspected, and why Linux matters before Docker and cloud hosting.

Linux exists because the software industry needed an open, Unix-like operating
system that could run across many hardware and server environments. It became
the dominant operating-system foundation for cloud infrastructure,
containers, DevOps tooling, and open-source server software. Microsoft did not
make .NET cross-platform by accident. .NET had to meet the operating system
where much of modern server computing already lived.

For the reader of this book, Linux is not a replacement for everything you
know about Windows. It is a second operating-system mental model. You already
understand processes, services, files, permissions, networking, logs, and
deployment. This chapter translates those ideas.

## Where This Fits

Linux is the operating-system layer underneath many modern .NET runtime
environments.

```text
ASP.NET Core application
        |
        v
.NET runtime
        |
        v
Linux process
        |
        +-- filesystem
        +-- users and permissions
        +-- environment variables
        +-- sockets and ports
        +-- logs and service manager
        |
        v
VM, container host, cloud app platform, or Kubernetes node
```

Chapter 10 introduces Docker. Docker will make much more sense if Linux
processes, filesystems, users, ports, and environment variables are already
familiar. Chapter 12 returns to hosting. Chapter 18 introduces Kubernetes,
where Linux concepts appear again underneath pods and containers.

This chapter is about orientation, not mastery. You need enough Linux to read
commands, diagnose common hosting problems, and avoid Windows assumptions.

## Connection to the Reader's Existing Model

Windows and Linux solve similar operating-system problems with different
conventions.

A Windows process maps to a Linux process. Both have process IDs, memory,
threads, environment variables, open files, and network connections.

A Windows service maps roughly to a `systemd` service on many Linux
distributions. Both define long-running background processes that start,
stop, restart, and write logs. The analogy is useful, but Linux distributions
can vary, and containers often run a process directly without `systemd`.

An IIS application pool identity maps to a Linux user account or service user.
Both determine what the running process can access. The difference is that
Linux file permissions and ownership are visible almost everywhere and are
central to daily troubleshooting.

`C:\inetpub\wwwroot` maps conceptually to an application directory such as
`/var/www/myapp`, `/opt/myapp`, or a container working directory. The Linux
filesystem does not use drive letters. Everything hangs from `/`, the root of
the filesystem.

Windows Event Log maps partly to `journalctl`, partly to application console
logs, and partly to files under `/var/log`. In containers and cloud platforms,
writing structured logs to standard output is often preferred.

Windows environment variables map directly to Linux environment variables, but
syntax differs. PowerShell uses `$env:ASPNETCORE_ENVIRONMENT`; shells such as
Bash use `$ASPNETCORE_ENVIRONMENT`.

The analogy breaks down when you assume the same defaults. Linux paths are
case-sensitive on most filesystems. `/app/config.json` and `/app/Config.json`
are different names. File execution depends on permission bits. Services often
run as non-root users. Package installation, certificates, process management,
and shell behavior are different enough to deserve attention.

## Layer 1 — Conceptual Model

Linux is an operating-system family built around the Linux kernel plus a
userspace of tools, libraries, shells, package managers, and distributions.

For .NET developers, Linux solves these practical problems:

- it provides a common server runtime environment;
- it underpins most container hosts;
- it is widely used by cloud platforms;
- it supports command-line automation well;
- it gives lightweight server images for APIs and services;
- it provides a common environment for CI runners and deployment targets.

It does not solve these problems by itself:

- it does not make an application cloud-native;
- it does not remove the need for deployment discipline;
- it does not make security automatic;
- it does not replace SQL Server, IIS, or Windows where those are still the
  right fit;
- it does not make every Windows-specific .NET application portable.

The conceptual center is this:

```text
Linux hosts processes.
Processes read files, environment variables, ports, and permissions.
.NET applications are processes.
```

Once you understand that, Linux becomes less mysterious. An ASP.NET Core app
on Linux is still a process listening on a port, reading configuration,
calling dependencies, writing logs, and exiting with a status code.

## Layer 2 — System Relationships

The Linux kernel owns low-level resources: CPU scheduling, memory, processes,
filesystems, devices, networking, and permissions.

The distribution packages the kernel with userspace tools and conventions.
Ubuntu, Debian, Red Hat Enterprise Linux, Fedora, Alpine, SUSE, and others are
Linux distributions. They differ in package managers, default tools, support
policies, filesystem layout details, and operational conventions.

The shell receives commands from the user or script. Bash is common, though
many shells exist. The shell expands variables, runs programs, redirects
input/output, and connects commands.

The package manager installs and updates software. Debian and Ubuntu commonly
use `apt`. Red Hat-family systems commonly use `dnf` or `yum`. Alpine uses
`apk`. .NET installation instructions vary by distribution.

The filesystem stores application files, configuration, logs, certificates,
temporary data, and mounted volumes. Linux uses `/` as the root and paths such
as `/etc`, `/var`, `/usr`, `/home`, `/tmp`, and `/opt`.

Users and groups define ownership and access. A process runs as a user. That
user's permissions determine whether the process can read a file, write a
directory, bind to certain ports, or access mounted resources.

Networking exposes sockets and ports. An ASP.NET Core process may listen on
`http://0.0.0.0:8080` inside a Linux host or container. A firewall, reverse
proxy, container port mapping, or cloud load balancer may determine whether
clients can reach it.

The .NET runtime executes the application. Microsoft provides .NET downloads
and installation guidance for Windows, macOS, and many Linux distributions,
and .NET 10 downloads include Linux SDK/runtime builds for multiple
architectures.

Failure boundaries include missing packages, wrong CPU architecture, file
permission errors, case-sensitive path bugs, missing environment variables,
ports already in use, certificate trust problems, line-ending issues, native
library dependencies, and differences between a full VM and a minimal
container image.

## Layer 3 — Core Mechanics

The filesystem starts at `/`.

```text
/              root of the filesystem
/home          user home directories
/etc           system configuration
/var           variable data such as logs and application state
/tmp           temporary files
/usr           installed user-space programs and libraries
/opt           optional or vendor application software
```

Paths use forward slashes:

```text
/home/steve/appsettings.json
/var/log/myapp/app.log
/opt/orders-api/Orders.Api.dll
```

Permissions are commonly shown with `ls -l`:

```text
-rw-r--r--  1 app app  1024 Jul 22 appsettings.json
drwxr-xr-x  2 app app  4096 Jul 22 logs
```

The first character indicates type: `-` for file, `d` for directory. The next
groups represent read, write, and execute permissions for owner, group, and
others.

Processes can be inspected:

```bash
ps aux
ps -ef
```

Ports can be inspected:

```bash
ss -tulpn
```

Environment variables can be viewed:

```bash
printenv
echo "$ASPNETCORE_ENVIRONMENT"
```

A .NET app can run directly:

```bash
dotnet Orders.Api.dll
```

Or a published self-contained app can run as an executable:

```bash
./Orders.Api
```

The execute bit matters. If Linux says "permission denied" when running a
file, it may not be executable:

```bash
chmod +x Orders.Api
```

Logs may come from the process output:

```bash
dotnet Orders.Api.dll
```

Or from `systemd` when the app is configured as a service:

```bash
journalctl -u orders-api
```

These commands are not the whole Linux world. They are the beginning of the
Linux vocabulary a .NET developer needs.

## Layer 4 — Developer Workflow

Start by identifying the environment:

```bash
uname -a
cat /etc/os-release
whoami
pwd
```

Navigate the filesystem:

```bash
ls
ls -la
cd /tmp
mkdir chapter09
cd chapter09
```

Create and inspect a file:

```bash
echo "hello from linux" > message.txt
cat message.txt
ls -l message.txt
```

Inspect environment variables:

```bash
printenv | sort
export ASPNETCORE_ENVIRONMENT=Development
echo "$ASPNETCORE_ENVIRONMENT"
```

Check .NET:

```bash
dotnet --info
dotnet --list-runtimes
```

Create and run a .NET app:

```bash
dotnet new console -n LinuxDotnetDemo
cd LinuxDotnetDemo
dotnet run
```

Publish it:

```bash
dotnet publish -c Release
```

Find files:

```bash
find . -name "*.dll"
```

Inspect running processes:

```bash
ps -ef | grep dotnet
```

The workflow habit is to ask four questions:

```text
Where am I in the filesystem?
Which user am I?
Which process is running?
Which port or file is it trying to use?
```

Those four questions solve a surprising number of first-level Linux hosting
problems.

## Layer 5 — Production Usage

Production Linux hosting starts with ownership.

Do not run application processes as `root` unless there is a specific and
justified reason. Create a service user or use the platform's non-root runtime
model. File permissions should allow the application to read what it needs and
write only where it is expected to write.

Configuration should come from files, environment variables, secret stores, or
platform configuration, depending on the host. Avoid editing production
application binaries or source files on the server.

Secrets should not be stored in shell history, world-readable files, or
checked-in scripts. Linux permissions help, but a readable secret file is still
a secret exposure if too many users or processes can read it.

Security includes patching, user permissions, firewall rules, SSH access,
certificate trust, dependency updates, and process isolation. Linux is not
secure merely because it is Linux.

Reliability depends on service management, restart behavior, logs, health
checks, disk space, memory pressure, CPU pressure, and dependency availability.
On VM-style Linux hosting, `systemd` commonly owns service restart behavior.
In containers, the container platform usually owns restart behavior.

Deployment should be repeatable. Copying files manually into `/opt` may be
acceptable for learning, but production should use packages, artifacts,
containers, or deployment automation.

Observability depends on where logs go. A VM service may write to journald and
application logs. A containerized app should usually write logs to standard
output so the platform can collect them.

Scaling is usually handled outside the individual Linux process: multiple VMs,
containers, platform instances, or Kubernetes pods. The application still
needs to be stateless enough to scale safely.

Persistence should be explicit. Local Linux disk may be temporary in cloud or
container environments. Durable state belongs in databases, managed storage,
or mounted volumes designed for persistence.

Cost is affected by VM size, disk, network traffic, operational labor, support
subscriptions, and cloud platform choices. Linux can reduce licensing cost in
some scenarios, but it does not eliminate operations cost.

Local development optimizes for learning and convenience. Production optimizes
for least privilege, patching, repeatability, monitoring, and recoverability.

## Layer 6 — Tradeoffs and Alternatives

Use Linux hosting when the application benefits from container alignment,
cloud-native platform support, lower server footprint, open-source tooling,
or team familiarity with Linux operations.

Use Windows hosting when the application depends on Windows-specific APIs,
classic .NET Framework, COM components, Windows Authentication patterns,
desktop automation, vendor software, or an operations team and compliance
model built around Windows Server.

Use managed platforms when you do not want to administer Linux VMs directly.
Azure App Service, Azure Container Apps, AWS Elastic Beanstalk, AWS ECS,
Google Cloud Run, and similar services can run .NET workloads while hiding
some operating-system management.

Use containers when repeatable runtime packaging matters. Containers usually
run on Linux hosts, though Windows containers exist for Windows-specific
workloads.

Linux distributions are alternatives too. Ubuntu is common in cloud and
developer contexts. Debian is common for stability and base images. Red Hat
Enterprise Linux is common in enterprises with support requirements. Alpine is
common for small container images, though its musl C library can introduce
compatibility considerations. The right choice depends on support, image size,
package availability, security policy, and team experience.

Common overengineering mistakes:

- trying to become a Linux administrator before learning the basics needed for
  .NET hosting;
- running everything as `root` to avoid permission errors;
- assuming paths are case-insensitive;
- editing production files manually instead of redeploying;
- storing secrets in shell scripts;
- ignoring logs because they are not in Windows Event Viewer;
- choosing a minimal container image before understanding missing dependencies.

The state-of-the-art direction is not "Linux instead of Windows everywhere."
It is platform fit: Linux for cloud-native and container-friendly workloads,
Windows where Windows-specific value remains, and managed platforms where the
team should not own the OS layer directly.

## Layer 7 — Interview Perspective

Interviewers usually do not expect a .NET developer to be a senior Linux
administrator. They do expect comfort with the basics.

Concepts commonly tested:

- why Linux matters to modern .NET;
- filesystem layout and path differences;
- case-sensitive paths;
- users, groups, and permissions;
- processes and services;
- environment variables;
- ports and networking;
- logs and standard output;
- Linux in containers and cloud hosting;
- Windows versus Linux hosting tradeoffs.

Representative questions:

- "Why would an ASP.NET Core app run on Linux?"
- "What problems can case-sensitive paths cause?"
- "How would you check whether a .NET process is running?"
- "How would you inspect environment variables?"
- "What does `permission denied` usually suggest?"
- "Where would you expect logs to go on Linux?"
- "When would Windows Server still be the better host?"

A strong answer translates from concepts:

> "An ASP.NET Core app on Linux is still a process. I would check which user it
> runs as, which directory it uses, whether required environment variables are
> set, whether it can read its files, and whether it is listening on the
> expected port."

Common misconceptions:

- "Linux is required for modern .NET."
- "Linux knowledge means memorizing every command."
- "Containers mean I do not need to understand Linux."
- "If a file path works on Windows, it will work the same on Linux."
- "Running as root is fine if the server is private."
- "Linux logs all appear in one obvious place."

Small design scenario:

You deploy an ASP.NET Core API to a Linux VM. It starts locally on Windows but
fails in production. The logs say it cannot find `AppSettings.json`.

A good investigation would check the deployed filename, the code's expected
path, Linux case sensitivity, working directory, file permissions, and whether
configuration should come from environment variables instead of a copied file.

The strong answer avoids blaming Linux and inspects the operating-system
boundary.

## Hands-On Lab

Objective:

Practice the Linux commands and concepts most relevant to running a .NET
application.

Prerequisites:

- A Linux shell. This may be WSL, a Linux VM, a cloud shell, a container shell,
  or a native Linux machine.
- .NET SDK installed if you want to run the .NET steps.

Steps:

1. Identify the system:

   ```bash
   uname -a
   cat /etc/os-release
   ```

2. Identify your user and location:

   ```bash
   whoami
   pwd
   ```

3. Create a working directory:

   ```bash
   mkdir -p ~/chapter09
   cd ~/chapter09
   ```

4. Create and inspect files:

   ```bash
   echo "hello" > message.txt
   ls -la
   cat message.txt
   ```

5. Inspect permissions:

   ```bash
   ls -l message.txt
   ```

6. Work with an environment variable:

   ```bash
   export ASPNETCORE_ENVIRONMENT=Development
   echo "$ASPNETCORE_ENVIRONMENT"
   ```

7. Check .NET:

   ```bash
   dotnet --info
   ```

8. Create and run a console app:

   ```bash
   dotnet new console -n LinuxDotnetDemo
   cd LinuxDotnetDemo
   dotnet run
   ```

9. Inspect processes:

   ```bash
   ps -ef | grep dotnet
   ```

Expected results:

- You can identify the Linux distribution.
- You can navigate directories and inspect files.
- You can read permission output.
- You can set and read an environment variable.
- You can run a .NET application from a Linux shell.

Validation commands:

```bash
uname -a
cat /etc/os-release
whoami
pwd
ls -la
dotnet --info
dotnet run
```

Troubleshooting notes:

- If `dotnet` is not found, install the .NET SDK for your distribution or use
  a shell where it is already installed.
- If a command says `permission denied`, check file permissions and the current
  user.
- If a path is not found, check spelling and capitalization.
- If `grep dotnet` shows only the `grep` command, no matching .NET process may
  be running.

## Knowledge Check

1. Why does Linux matter to modern .NET development?
2. What is the practical difference between `C:\apps\api` and `/opt/api`?
3. Why can filename capitalization break a .NET app on Linux?
4. What does a Linux user account control for a running process?
5. How are environment variables useful for ASP.NET Core configuration?
6. Why should production services usually avoid running as `root`?
7. How do Linux logs differ between VM-style hosting and container hosting?
8. What is the relationship between Linux and Docker?
9. When is Windows Server still the right hosting choice?
10. What four questions should you ask first when diagnosing a Linux-hosted
    .NET app?

## Summary

Linux is not a detour from modern .NET. It is one of the operating-system
foundations underneath modern .NET hosting, containers, CI runners, cloud
platforms, and Kubernetes.

For a Windows developer, the most useful first step is translation. Linux has
processes, services, files, permissions, environment variables, ports, and
logs just as Windows does, but the conventions are different. Paths start at
`/`, filenames are usually case-sensitive, permissions are visible and central,
and many hosting workflows assume shell-based automation.

You do not need to become a Linux administrator before writing .NET
applications. You do need enough Linux fluency to understand where the process
runs, which user owns it, which files it can read, which port it listens on,
and where logs and configuration come from.

The next chapter builds on this by introducing Docker, where Linux process and
filesystem concepts become the foundation for images and containers.

## Sources

- [Install .NET on Windows, Linux, and macOS](https://learn.microsoft.com/en-us/dotnet/core/install/)
- [Download .NET 10.0](https://dotnet.microsoft.com/en-us/download/dotnet/10.0)
- [The Linux Foundation: It's not just the Linux operating system](https://www.linuxfoundation.org/blog/blog/the-linux-foundation-its-not-just-the-linux-operating-system)
- [About the Linux Foundation](https://www.linuxfoundation.org/about)
- [Stack Overflow Developer Survey 2025](https://survey.stackoverflow.co/2025/)

## Further Reading

- [Install .NET on Ubuntu](https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu)
- [Install .NET on Debian](https://learn.microsoft.com/en-us/dotnet/core/install/linux-debian)
- [Install .NET on Red Hat Enterprise Linux](https://learn.microsoft.com/en-us/dotnet/core/install/linux-rhel)
- [Linux Foundation Training](https://training.linuxfoundation.org/)
- [Linux.com](https://www.linux.com/)
