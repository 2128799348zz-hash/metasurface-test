%% 从监视器 T 的总场中分离 -1、0、+1 级次的相位包络。
% 输入：由 FDTD 监视器 T 导出的 T_nearfield_905nm.mat。
% 输出：去除偏转载波后的三路相位分布图。

clear; clc;

% 定义相对于本分析脚本的输入和输出路径。
this_dir = fileparts(mfilename('fullpath'));
input_file = fullfile(this_dir,'T_nearfield_905nm.mat');
output_file = fullfile(this_dir,'T_order_phase_maps_905nm.mat');
figure_file = fullfile(this_dir,'T_order_phase_maps_905nm.png');

% 读取由 Lumerical 导出的矩形网格复电场数据集。
S = load(input_file,'Edata');
Edata = S.Edata;
x = Edata.x(:);
y = Edata.y(:);

% 提取 z=1、频率索引=1、矢量分量=1 对应的复数 Ex。
% 转置后矩阵的行对应 y，列对应 x，便于按实际坐标绘图。
Ex = squeeze(Edata.E(:,:,1,1,1)).';

Ny = numel(y);
Nx = numel(x);
assert(isequal(size(Ex),[Ny,Nx]),'Edata.E 的数组尺寸不符合二维 XY 监视器格式。');

% 建立 FFT 坐标轴前，监视器的 x/y 采样必须均匀。
dx = mean(diff(x));
dy = mean(diff(y));
assert(max(abs(diff(x)-dx)) < 1e-12 && max(abs(diff(y)-dy)) < 1e-12, ...
    '监视器的 x/y 采样网格必须均匀。');

% Sx 决定各级次的横向载波：kx,N = N*2*pi/Sx。
Sx = 1350e-9;
%%%频率窗口
% 每个级次的圆形频谱窗口半径。
% 相邻级次频谱重叠时应减小它；级次频谱被截断时才增大它。
filter_radius = 0.7*pi/Sx;
orders = [-1,0,1];

% 建立空间频率坐标，并计算总复电场的二维 FFT。
kx = 2*pi*(-floor(Nx/2):ceil(Nx/2)-1)/(Nx*dx);
ky = 2*pi*(-floor(Ny/2):ceil(Ny/2)-1)/(Ny*dy);
[KX,KY] = meshgrid(kx,ky);
[X,~] = meshgrid(x,y);
F = fftshift(fft2(Ex));

phase_maps = zeros(Ny,Nx,3);
amplitude_maps = zeros(Ny,Nx,3);
complex_envelopes = zeros(Ny,Nx,3);

for q = 1:3
    % 选取以当前衍射级次载波为中心的频谱区域。
    kx_order = orders(q)*2*pi/Sx;
    spectral_mask = (KX-kx_order).^2 + KY.^2 <= filter_radius^2;

    % 逆 FFT 后得到仍包含线性偏转载波的该级次光场。
    order_field = ifft2(ifftshift(F.*spectral_mask));

    % 去除 exp(i*kx_order*x)，得到用于匹配的相位包络 C_N(x,y)。
    envelope = order_field.*exp(-1i*kx_order*X);
    amplitude = abs(envelope);
    phase = mod(angle(envelope),2*pi);
    % 分离后振幅接近零的位置相位没有意义，显示为 NaN。
    phase(amplitude < 0.05*max(amplitude(:))) = NaN;
    phase_maps(:,:,q) = phase;
    amplitude_maps(:,:,q) = amplitude;
    complex_envelopes(:,:,q) = envelope;
end

% 在统一的 [0, 2*pi] 范围内绘制三路去载波相位图。
figure('Color','w','Position',[100,100,1350,420]);
for q = 1:3
    subplot(1,3,q);
    imagesc(x*1e6,y*1e6,phase_maps(:,:,q));
    axis image xy;
    caxis([0,2*pi]);
    colorbar;
    xlabel('x [um]');
    ylabel('y [um]');
    title(sprintf('N = %d 级相位 [rad]',orders(q)));
end
exportgraphics(gcf,figure_file,'Resolution',300);

% 保存相位、振幅和复数包络，供后续比较目标相位。
save(output_file,'x','y','orders','filter_radius','phase_maps', ...
    'amplitude_maps','complex_envelopes');
