# Setup instructions

## 1. Installation

[System requirements](/system-requirements.md)
#### Enable acp in your project
```
fin acp enable
```
#### Setup the acp server
The easiest way to test andock-ci is to create a cloud box on aws or digital ocean etc. with ubuntu 16.04 or 18.04.

After that run:

```
fin acp connect
fin acp server:install
fin acp server:ssh-add "ssh-rsa AAAAB3NzaC1yc2EA ..."
```

#### Generate project configuration
```
fin acp config:generate
```

This will create some required config files and templates for init, build, test and update hooks. 
#### Initialize remote environment
```
fin acp fin init
```

#### Update remote environment
```
fin acp fin up
```
### Congratulations, the installation is finished!


## Example hook configurations:
1. [Drupal](example-drupal-hooks.md)