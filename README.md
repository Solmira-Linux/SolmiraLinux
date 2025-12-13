Solmira Linux
=============

Solmira Linux is a free and open-source Linux distribution based on Arch Linux. The goal of Solmira Linux is to provide an easy-to-use distribution with the base of Arch. Keep in mind that as of right now, this distro is broken. Installer doesn't work and probably isn't safe to use as a daily driver.

Note that development of this project happens on Codeberg. So please open pull requests there.




## Getting Started

You can build an ISO through the Codeberg repository, which will allow you to receive the latest updates.

You can also build the ISO through the GitHub mirror, but there is a chance for this mirror to not be properly updated, so always use Codeberg if you can. 


### All repositories:

[Codeberg (Recommended)](https://codeberg.org/Solmira-Linux/SolmiraLinux)

[GitHub Mirror](https://github.com/Solmira-Linux/SolmiraLinux)


## System Requirements
These are the recommended system requirements to build a Solmira Linux image:
- Arch Linux (Kernel version 6.12+ recommended)
- Fast internet connection (Ethernet recommended)

Of course, you can also use any other Arch-based distro like EndeavourOS to build this image.

### Prerequisites

To get started, you will need to make sure you have the archiso packaged installed.
  ```bash
  sudo pacman -S archiso
  ```

### Build Process

#### 1. Clone the repo
   ```bash
   git clone https://codeberg.org/Solmira-Linux/SolmiraLinux.git
   ```
   
#### 2. Change into the new directory
   ```bash
   cd SolmiraLinux/solmira
   ```
   This is the directory that contains the necessary files to build a live image.
   
   
#### 3. Build the ISO.
   
   You can then build the image with this command:
   ```bash
   sudo mkarchiso -v .
   ```

   The ISO will be stored in the "out" folder.