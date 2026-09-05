%% generate_target_phases_905nm.m
% 905 nm 正入射三通道超表面验证：生成供 FDTD library 匹配的目标相位。
%
% 最终实验计划：
%   N = -1 : focused OAM beam, l = +1
%   N =  0 : planar (Gaussian input keeps its original wavefront)
%   N = +1 : zero-order Bessel beam
%
% 重要：本文件的 phiC_* 是要与单 supercell FDTD library 中 C_N 的
% 相位比较的“结构部分目标相位”。固定周期 Sx 产生的衍射级次方向
% 已包含在 Fourier/Floquet 级次 N 中，不能再作为逐个 supercell 的
% 相位目标叠加到 phiC_* 内。
%
% 输出：
%   target_phases_905nm.mat    所有相位、坐标和参数
%   target_phase_maps_905nm.png 相位图（运行时生成）
%
% 需要按实际设计/实验修改的三个参数：
%   beta_deg : Bessel 锥角（默认 8 deg）
%   f_um     : focused-OAM 焦距（默认 30 um）
%   l        : OAM 拓扑荷（默认 +1）

clear; clc;

%% 1. 实验与器件参数（SI 单位）
lambda0 = 905e-9;      % 工作波长 [m]
Sx      = 1350e-9;     % x 向 supercell 周期 [m]
Sy      = 450e-9;      % y 向 supercell 周期 [m]
Nx      = 20;          % x 向 supercell 数，器件宽度 Lx = 27 um
Ny      = 60;          % y 向 supercell 数，器件宽度 Ly = 27 um

beta_deg = 8;          % +1 级 Bessel 锥角 [deg]
f_um     = 30;         % -1 级 focused OAM 焦距 [um]
l        = +1;         % -1 级 OAM 拓扑荷

assert(lambda0 > 0 && Sx > 0 && Sy > 0, 'lambda0, Sx, Sy 必须为正值。');
assert(Nx >= 1 && Ny >= 1 && mod(Nx,1) == 0 && mod(Ny,1) == 0, ...
    'Nx 和 Ny 必须为正整数。');
assert(abs(lambda0/Sx) <= 1, ...
    'Sx 太小：+/-1 级在空气侧不能传播。');

%% 2. 以每个 supercell 中心为采样点建立器件平面坐标
Lx = Nx * Sx;
Ly = Ny * Sy;
x = ((0:Nx-1) + 0.5) * Sx - Lx/2;
y = ((0:Ny-1) + 0.5) * Sy - Ly/2;
[X, Y] = meshgrid(x, y);       % 相位矩阵尺寸为 Ny x Nx
R     = hypot(X, Y);
Theta = atan2(Y, X);

k0   = 2*pi/lambda0;
beta = deg2rad(beta_deg);
f    = f_um * 1e-6;
kr   = k0 * sin(beta);

%% 3. 三个级次的结构部分目标相位 phiC_N（供 FDTD library 匹配）
% N = 0：不额外施加空间相位；准直 Gaussian 入射时保持 Gaussian 波前。
phiC_0 = zeros(Ny, Nx);

% N = +1：轴锥相位。正负号取决于所采用的时间因子约定；这里采用
% exp(-i*omega*t) 下常用的 +kr*R 写法。若传播验证显示为发散锥，
% 将下一行改为 -kr*R 即可。
phiC_p1 = kr * R;

% N = -1：会聚球面相位 + 螺旋相位。采用与上式相同的相位约定。
phi_focus = k0 * (sqrt(R.^2 + f.^2) - f);
phi_oam   = l * Theta;
phiC_m1  = phi_focus + phi_oam;

% 所有相位限制为 [0, 2*pi)，以便同 FDTD library 的相位作环形比较。
phiC_0  = mod(phiC_0,  2*pi);
phiC_p1 = mod(phiC_p1, 2*pi);
phiC_m1 = mod(phiC_m1, 2*pi);

%% 4. 级次方向与“含空间载波”的连续相位表达式（仅用于核查/展示）
% 对固定 Sx，Floquet 级次中心方向为 sin(theta_N)=N*lambda0/Sx。
theta_m1_deg = asind(-lambda0/Sx);
theta_0_deg  = 0;
theta_p1_deg = asind(+lambda0/Sx);

% 这些 phiT_N 是连续平面中的理论总相位表达式。实际进行 library 匹配时
% 请使用上面的 phiC_m1、phiC_0、phiC_p1，而非 phiT_N。
phiT_m1 = mod(-2*pi*X/Sx + phi_focus + phi_oam, 2*pi);
phiT_0  = phiC_0;
phiT_p1 = mod(+2*pi*X/Sx + kr*R, 2*pi);

%% 5. 保存 MAT 文件，供后续结构匹配与角谱传播脚本直接调用
params = struct( ...
    'lambda0_m', lambda0, 'Sx_m', Sx, 'Sy_m', Sy, ...
    'Nx', Nx, 'Ny', Ny, 'Lx_m', Lx, 'Ly_m', Ly, ...
    'beta_deg', beta_deg, 'f_um', f_um, 'topological_charge_l', l, ...
    'theta_m1_deg', theta_m1_deg, 'theta_0_deg', theta_0_deg, ...
    'theta_p1_deg', theta_p1_deg, 'kr_per_m', kr);

save('target_phases_905nm.mat', ...
    'X', 'Y', 'R', 'Theta', ...
    'phiC_m1', 'phiC_0', 'phiC_p1', ...
    'phiT_m1', 'phiT_0', 'phiT_p1', 'params');

%% 6. 绘图并保存，单位为 rad；行=y，列=x
figure('Color', 'w', 'Position', [100 100 1300 420]);
phase_maps = {phiC_m1, phiC_0, phiC_p1};
titles = { ...
    sprintf('C_{-1}: focused OAM (l = %+d)', l), ...
    'C_0: planar wavefront', ...
    sprintf('C_{+1}: Bessel (\beta = %.1f^\circ)', beta_deg)};

for n = 1:3
    subplot(1, 3, n);
    imagesc(x*1e6, y*1e6, phase_maps{n});
    axis image xy;
    xlabel('x [\mum]'); ylabel('y [\mum]');
    title(titles{n});
    colormap(gca, hsv(256));
    caxis([0 2*pi]);
    cb = colorbar;
    ylabel(cb, 'phase [rad]');
end
sgtitle(sprintf(['Target phases for 905 nm, S_x = %.0f nm, ', ...
    '\theta_{\pm1} = \pm%.2f^\circ'], Sx*1e9, theta_p1_deg));
exportgraphics(gcf, 'target_phase_maps_905nm.png', 'Resolution', 300);

%% 7. 命令行摘要
fprintf('Target phase files created successfully.\\n');
fprintf('MAT file : target_phases_905nm.mat\\n');
fprintf('Figure   : target_phase_maps_905nm.png\\n');
fprintf('Diffraction angles (air): -1 = %.2f deg, 0 = %.2f deg, +1 = %.2f deg\\n', ...
    theta_m1_deg, theta_0_deg, theta_p1_deg);
fprintf('Device size: %.2f um x %.2f um (%d x %d supercells).\\n', ...
    Lx*1e6, Ly*1e6, Nx, Ny);
