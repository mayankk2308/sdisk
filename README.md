![Header](/Resources/header.png)
**SDisk** allows you to set automated scripts or tasks based on disk activity. For example, quitting an application once a particular disk is ejected, launching an application when a particular disk is mounted, initiating backups or file transfers, and more.

## Contents
A brief table of contents for all you need to know:
- [Requirements](https://github.com/mayankk2308/sdisk#Requirements)

  System requirements and important pre-requisites.

- [Installation](https://github.com/mayankk2308/sdisk#Installation)

  Installation requirements and relevant basics.

- [Usage](https://github.com/mayankk2308/sdisk#Usage)

  Learn the basics of the minimal user interface and configuration, and get automating.

- [Support](https://github.com/mayankk2308/sdisk#Support)

  Instructions for software support and how to reach out to the developer(s).

- [License](https://github.com/mayankk2308/sdisk#License)

  By installing this software, you adhere to bundled license.

- [Disclaimer](https://github.com/mayankk2308/sdisk#Disclaimer)

  By using this software, you acknowledge the provided disclaimer.

- [Under the Hood](https://github.com/mayankk2308/sdisk#Under-The-Hood)

  A list and short description of any incorporated open source components.


## Requirements
**SDisk** requirements are summarized in the following table:

| Item | Requirement | Description |
| :--: | :---------: | :---------: |
| macOS | **10.14+** | It is difficult to test on previous version of macOS at this time, hence a minimum target for Mojave was set. |
| Automation Permissions | **Allow** | It is typically a very roundabout to be able to add an application as a **Login Item**. The approach applied here is simpler but requires user permissions for automation. |
| Some External Drives | **Required** | Scripting is not possible on internal drives since the boot drive cannot be mounted or disconnected, and there isn't much purpose served automating over internal volumes. |