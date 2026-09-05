文件：build_905nm_supercell.lsf

软件：Ansys Lumerical FDTD Solutions。

用途：
建立一个无限周期重复的单个 supercell，用于扫描双 TiO2 矩形棱柱的几何参数，
并建立 -1、0、+1 级次的 FDTD library。

模型设定：
  工作波长：905 nm。
  入射光：从空气侧沿 -z 方向正入射的 x 偏振平面波。
  基底：SiO2，初始折射率 n = 1.45。
  棱柱：TiO2，初始折射率 n = 2.30，高度 650 nm。
  上包层：空气。
  透射监视器：基底侧二维频域监视器，名称为 T。
  x/y 边界：Periodic。
  z 边界：PML。
  周期：Sx = 1350 nm，Sy = 450 nm。

操作步骤：
  1. 在 FDTD Solutions 中新建空白工程。
  2. 打开并运行 build_905nm_supercell.lsf。
  3. 在 Layout 中检查 SiO2 基底和两根 TiO2 柱的位置及尺寸。
  4. 在 FDTD 的 Advanced Options 中确认 PML profile 使用 Steep angle。
  5. 点击 Run。
  6. 在 Script Prompt 运行 extract_T_orders。
  7. 修改 extract_T_orders.lsf 中的 sample_id，为每组结构保存独立结果。

提取结果：
  T_orders_<sample_id>.txt：三行数据，分别为 -1、0、+1 级的级次编号、效率 eta_N、
  相位 phi_N（rad）。
  T_orders_<sample_id>.ldf：同一组数值及复振幅，供后续读取。

注意：
  当前棱柱横向尺寸、位置和高度只是第一组可运行的起点，并非最终优化结构。
  扫描时应至少改变两个棱柱的 x/y 尺寸、x 位置和高度，且始终保持两者不重叠。
  当前 Sx = 1350 nm 时，透射进入 SiO2 后 +/-2 级也会传播；若只希望输出
  -1、0、+1 三个级次，应把 Sx 改到 624 nm < Sx < 1248 nm，例如 1100 nm，
  并同步更新 MATLAB 目标相位脚本中的 Sx。
  当前 TiO2 和 SiO2 均是无损、常数折射率近似；进入最终设计时应使用实际薄膜的
  椭偏 n(lambda)、k(lambda) 数据替换。
