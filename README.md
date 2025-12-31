# Luminus Server - Database Backup Utility

This repository contains a robust batch automation tool designed to manage **MariaDB** database backups for the Luminus RP server environment.

It features a modern, colour-coded command-line interface and is engineered to provide secure, version-agnostic SQL dumps suitable for both production backups and development environment replication.

## Key Features

* **Dual Mode Operation:**
    * **Full Backup:** Exports the entire database (Structure + Data), ensuring a complete snapshot of the server state.
    * **Structure Only:** Exports only the table schemas. Crucially, this mode **automatically sanitises `AUTO_INCREMENT` values**, making it perfect for resetting the database or establishing fresh development environments.
* **Smart Sanitisation:** Utilises PowerShell to strip MariaDB version-specific comments (e.g., `/*!40000 ... */`) and reset counters, ensuring the SQL is clean and compatible across different environments.
* **Persistent Configuration:** Automatically generates a `settings.ini` file on the first run to store your preferred backup destination, eliminating the need to edit the script for basic setup.
* **Safety Mechanisms:** Includes built-in failsafes to prevent permission errors and verifies the integrity of the generated files before confirming success.

## Prerequisites

To utilise this utility, the host machine must meet the following requirements:

* **Operating System:** Windows 10/11 or Windows Server.
* **Database Engine:** MariaDB (Script defaults to version 12.1 path).
* **Shell:** Windows PowerShell (required for the text processing logic).

## Setup & Configuration

### 1. Initial Setup
On the first execution, the script will enter **Initialisation Mode**:
1.  Run the `.bat` file.
2.  The interface will prompt you to specify a destination directory for your backups.
    * You may enter a relative path (e.g., `.\backupdb`) or an absolute path (e.g., `C:\Backups\Luminus`).
    * Pressing **Enter** without typing uses the default `.\backupdb`.
3.  This setting is saved to `settings.ini`. Future runs will load this configuration automatically.

### 2. Changing the Backup Location
To change the destination folder after the initial setup, simply **delete the `settings.ini` file**. The script will re-prompt you for the configuration on the next run.

### 3. Adjusting MariaDB Version
If the host machine uses a different version of MariaDB (other than 12.1), you must update the executable path in the script:
1.  Open the `.bat` file in a text editor.
2.  Locate the `CONFIGURATION` block.
3.  Update the `MYSQL_PATH` variable:
    ```bat
    set "MYSQL_PATH=C:\Program Files\MariaDB [YOUR_VERSION]\bin\mysqldump.exe"
    ```

## Usage

Run the script and select your desired operation from the menu:

* **[1] FULL BACKUP:** Use this for daily production snapshots. It includes `DROP DATABASE` and `CREATE DATABASE` commands to ensure a clean restoration.
* **[2] STRUCTURE ONLY:** Use this when updating the repository or sharing the database schema with developers. It removes all player data and resets IDs to 1.

## Troubleshooting

* **"Executable Not Found":** Ensure the `MYSQL_PATH` inside the script matches your actual MariaDB installation folder.
* **"Permission Denied":** Ensure the script has write access to the destination folder. If saving to the root of C:, run the script as Administrator.
* **Visual Glitches:** The script uses ANSI colour codes. If you see strange characters instead of colours, ensure you are using a modern terminal (Windows Terminal or CMD on Windows 10/11).

---

**Author:** Luminus Server Development Team