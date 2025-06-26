# Common Role

此目录下的 `common` 角色提供主机初始化配置脚本和模板。

## Ubuntu 20.04+（推荐）

在部分精简安装的系统中，`fuse-overlayfs` 包位于 `universe` 软件源。如果在执行 `install-packages.sh` 脚本时提示无法找到该包，可按照以下步骤手动启用该仓库并安装：

```bash
sudo add-apt-repository universe
sudo apt update
sudo apt install -y fuse-overlayfs
```

启用 `universe` 仓库后，再次运行角色即可完成所需依赖的安装。
