# Configure your docksal project.
#### Add acp container to your .docksal/docksal.yml.
```
  # ACP
  acp:
    image: andockci/acp:dev-latest
```
#### Start acp container.
```
fin up
```
#### Install server. (If it's not done already.)
See [Server setup](/install-server.md)

#### Configure your docksal project.
```
acp config:generate
```
#### Init remote docksal.
```
acp fin init
```
## Congratulation your are done!.
