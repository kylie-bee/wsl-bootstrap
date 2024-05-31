# WSL Bootstrap Scripts

This repo holds my preferred WSL setup as a bash script. It is intended to be run on a fresh WSL installation.

You must ensure the `.env` file is in the user's home directory before running the script.

## Usage

To install a fresh WSL instance, run the following command:

```powershell
wsl --install -d <DistroName>
```

Then, copy the `.env` file to the user's home directory by running the following command (assuming you are in the root of the repo):

```bash
cp .env ~
```

Finally, run the following command to install the setup:

```bash
bash setup.sh
```

## Notes

You can see what Linux distributions are available with the following command:

```powershell
wsl --list --online
```

If you need to uninstall a previous installation, you can either do so from the `Add or remove programs` settings or by running the following command:

```powershell
wsl --unregister <DistroName>
```

> In some cases, you must uninstall from the `Add or remove programs` settings to remove the distro completely.
