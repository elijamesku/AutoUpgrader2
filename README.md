# 7-Zip Auto-Updater for Intune

This project automates the installation and periodic updating of 7-Zip on Windows machines using Microsoft Intune. It ensures that 7-Zip is always up to date by:

- Uninstalling any existing version of 7-Zip.
- Downloading and installing the latest version from the official website.
- Setting up a scheduled task to check for updates every 14 days.


## Getting Started

### Prerequisites

- Windows 10 or later.
- Microsoft Intune environment.
- [IntuneWinAppUtil.exe](https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool) for packaging the application.

### Packaging the Application

1. Clone this repository to your local machine.

2. Use the `IntuneWinAppUtil.exe` tool to package the application:


Replace `"C:\Path\To\7Zip-AutoUpdater"` with the path to your cloned repository and `"C:\Path\To\Output"` with your desired output directory.

### Deploying via Intune

1. In the Microsoft Endpoint Manager admin center, go to **Apps** > **Windows** > **Add**.

2. Select **App type** as **Windows app (Win32)** and click **Select**.

3. In the **App package file** pane, upload the `.intunewin` file generated earlier.

4. Configure the app information as desired.
