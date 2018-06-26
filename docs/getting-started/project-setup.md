# Configure your docksal project.
#### Add acp container to your .docksal/docksal.yml.
```
  # ACP
  acp:
    image: andockci/acp:dev-latest
```
#### Restart docksal.
```
fin restart
```
#### Install server. (If it's not done already.)
See [Server setup](../getting-started/install-server.md)
#### Configure your docksal project.
```
acp config:generate
```
#### Init remote docksal.
```
acp fin init
```
## Done.