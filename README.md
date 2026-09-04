## Laravel Deployment Scripts

基于 releases 目录 + symlink 模式的 Laravel 项目部署工具。

### 命令

```bash
Deployment.sh deploy <项目名称> <组织/仓库> <部署分支>     # 部署项目
Deployment.sh status <项目名称>                            # 查看部署状态
Deployment.sh rollback <项目名称>                          # 回滚到上一版本
Deployment.sh versions <项目名称>                          # 列出所有版本
Deployment.sh switch <项目名称> <版本>                     # 切换到指定版本
Deployment.sh config <基础目录> <执行用户> <保留版本数量>  # 配置基础工具
Deployment.sh check                                        # 检查依赖
```