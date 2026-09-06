文件：build_905nm_supercell.lsf

软件：Ansys Lumerical FDTD Solutions。

用途：
建立一个无限周期重复的单个 supercell，用于扫描双 TiO2 矩形棱柱的几何参数，
并建立 -1、0、+1 级次的 FDTD library。

模型设定：
  工作波长：905 nm。
  入射光：从空气侧沿 -z 方向正入射的 x 偏振平面波。
  基底：SiO2，初始折射率 n = 1.45。
  棱柱：TiO2，初始折射率 n = 2.30；两柱共用 height 用户参数（初始可设为 630 nm）。
  上包层：空气。
  透射监视器：基底侧二维频域监视器，名称为 T。
  x/y 边界：Periodic。
  z 边界：PML。
  周期：Sx = 1350 nm，Sy = 450 nm。

操作步骤：
  1. 在 FDTD Solutions 中新建空白工程。
  2. 打开并运行 build_905nm_supercell.lsf。
  3. 将 model_setup_gap_control.lsf 粘贴到根分析组 model 的 Setup -> Script。
  4. 在 model 的 User properties 中填入固定初值（单位为 um）：
       x1=-0.25，y1=0，x1span=0.25，y1span=0.20，y2=0，height=0.63，
       x2span=0.10，y2span=0.10，gap=0.04。
  5. 在 Layout 中检查 SiO2 基底和两根 TiO2 柱的位置及尺寸。
  6. 在 FDTD 的 Advanced Options 中确认 PML profile 使用 Steep angle。
  7. 点击 Run。
  8. 单次仿真后，可在 Script Prompt 运行 extract_T_orders。

Parameter Sweep（210 组粗扫描）：
  - 直接扫描 model 的 User properties；不再在 Sweep 中填写 x2。
    height 也可以作为第四个扫描参数；脚本会同步移动光源、FDTD 顶部边界和局部网格。
  - 三个参数均选择 Type = Length：
      ::model::x2span：0.10 至 0.40 um，步长 0.05 um（7 点）；
      ::model::y2span：0.10 至 0.30 um，步长 0.05 um（5 点）；
      ::model::gap：0.04 至 0.24 um，步长 0.04 um（6 点）。
  - 建立三层 Nested sweep，才能得到三个参数的全部笛卡尔组合：
      6 × 5 × 7 = 210 组。
  - 每次更新 User property 后，model 的 Setup script 会自动令
      x2=x1+x1span/2+gap+x2span/2，
    所以 gap 始终是两柱的实际边缘间隔。
  - Setup script 会先检查几何合法性：各尺寸为正、gap 为正、两个柱均不接触
    周期边界、两个柱彼此不接触。未来扫描 x1 时，同样受此检查保护。
    若参数不合法，脚本会在写入几何前输出提示并以 break 停止。请将该扫描点
    排除或收窄扫描范围；Parameter Sweep 不应依赖 break 自动跳过无效点，
    因为它可能继续使用上一组已写入的几何。
  - 当前对象在 group 内，脚本使用层级名称：
      unit group::TiO2_prism_1、
      unit group::TiO2_prism_2、
      analysis group::source_905nm。
    以后若在 GUI 中重命名 group 或对象，必须同步更新这些名称。
  - 将 analysis_group_T_orders_script.lsf 粘贴到 model 的 Analysis -> Script，
    并将 eta_m1、eta_0、eta_p1、phi_m1、phi_0、phi_p1 加为 Analysis Results，
    即可把六个标量结果写入 sweep 表。

提取结果：
  T_orders_<sample_id>.txt：三行数据，分别为 -1、0、+1 级的级次编号、效率 eta_N、
  相位 phi_N（rad）。
  T_orders_<sample_id>.ldf：同一组数值及复振幅，供后续读取。

注意：
  粗扫描阶段固定 pillar 1：Lx1=250 nm、Ly1=200 nm、x1=-250 nm、y1=0。
  pillar 2 扫描 Lx2=100:50:400 nm、Ly2=100:50:300 nm 与 gap=40:40:240 nm。
  若使用 Parameter Sweep，应优先使用 model_setup_gap_control.lsf；它会在每组
  参数更新时自动运行。set_prism2_position_from_gap.lsf 保留作手动单次检查用。
  当前 Sx = 1350 nm 时，透射进入 SiO2 后 +/-2 级也会传播；若只希望输出
  -1、0、+1 三个级次，应把 Sx 改到 624 nm < Sx < 1248 nm，例如 1100 nm，
  并同步更新 MATLAB 目标相位脚本中的 Sx。
  当前 TiO2 和 SiO2 均是无损、常数折射率近似；进入最终设计时应使用实际薄膜的
  椭偏 n(lambda)、k(lambda) 数据替换。
