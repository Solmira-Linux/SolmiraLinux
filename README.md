Solmira Linux
=============

Solmira Linux is a free and open-source Linux distribution based on Arch Linux. The goal of Solmira Linux is to provide an easy-to-use distribution with the base of Arch.


## Getting Started

Solmira Linux ISOs can be found in the Releases page.

You can also build an ISO through the GitHub repository, which will allow you to receive the latest updates.

### Prerequisites

To get started, you will need to make sure you have the archiso packaged installed.
  ```bash
  sudo pacman -S archiso
  ```

### Build Process

#### 1. Clone the repo
   ```bash
   git clone https://github.com/Solmira-Linux/SolmiraLinux.git
   ```
   
#### 2. Change into the new directory
   ```bash
   cd SolmiraLinux/solmira
   ```
   This is the directory where you will make changes to the distribution.
   
   
#### 3. Build the ISO.
   
   Once you finish your changes, you can test them out by building the ISO.
   ```bash
   sudo mkarchiso -v .
   ```

   The ISO will be stored in the "out" folder.