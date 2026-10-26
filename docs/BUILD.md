# 构建与验证

使用 Godot 4.7.2 标准版、匹配的 Windows x86_64 导出模板和 Python 3.10 以上版本。默认图形后端为 Mobile / Direct3D 12。

```powershell
python -m pip install -r requirements-dev.txt
python tools/build_public.py import --engine "Godot 可执行文件路径"
python tools/build_public.py check --engine "Godot 可执行文件路径"
python tools/build_public.py smoke --engine "Godot 可执行文件路径"
python tools/build_public.py restore --engine "Godot 可执行文件路径"
python tools/build_public.py export --engine "Godot 可执行文件路径" --templates-dir "Windows 模板目录"
python tools/build_public.py audit
python tools/build_public.py package
```

源码含已经烘焙的 224 个区块与全局、远景场景。日常运行无需重新生成几何。修改建筑生成代码后执行 `python tools/build_public.py bake --engine "Godot 可执行文件路径"`，使用真实图形后端，默认复用随源码提供的地形缓存。烘焙成功后运行场景公开内容检查。无头后端不能保存有效的 MultiMesh 实例数据。

`tools/craft160_world_assets.py` 与 `tools/craft160_geometry.py` 提供可编辑精工构件生成器，输出到 `assets/craft160`。AI 生成的两张装饰图保留原文件及来源记录；生成器不会请求在线服务。

6144×6144 的 RG16F 地表材质数据无损拆为三个 48 MiB 的 `terrain_field110.part0`、`part1`、`part2`，运行时拼接，保持原始精度和 1600×1600 米覆盖。地形表生成器使用同一覆盖范围，修改表时应选 6144 分辨率并按原顺序拆分。禁止用旧版较小覆盖的数据替换。

构建、测试档和日志均写入项目的 `.runtime`、`reports` 或 `builds`。Windows 模板目录应含 `windows_release_x86_64.exe`。压缩包和校验文件输出至 `dist`。

个人库、待导入素材、存档、缓存和构建产物均被 Git 排除。发布前执行 `audit`，检查新增资源登记、第三方许可及压缩包清单。
