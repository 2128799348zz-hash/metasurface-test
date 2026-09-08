%% match_structure_library_905nm.m
% 只按三路相位进行双柱单元匹配。
% 每一路振幅均归一化为 1，评价函数为：
% f = |exp(i*phi_-1)-exp(i*phi_-1,target)|^2
%   + |exp(i*phi_0 )-exp(i*phi_0,target )|^2
%   + |exp(i*phi_+1)-exp(i*phi_+1,target)|^2。
% 对每个超胞位置，选择 f 最小的结构库单元。

clear; clc;

this_dir = fileparts(mfilename('fullpath'));
library = load(fullfile(this_dir, '905nm_dual_pillar_structure_library.mat'));
target = load(fullfile(fileparts(this_dir), '905nm_目标相位', ...
    'target_phases_905nm.mat'));

% 读取结构库中唯一需要参与匹配的三组相位。
phi_m1 = library.phi_m1_data.phi_m1;
phi_0  = library.phi_0_data.phi_0;
phi_p1 = library.phi_p1_data.phi_p1;
assert(isequal(size(phi_m1), size(phi_0), size(phi_p1)), ...
    '三组结构库相位的数组尺寸不一致。');

% 当前 Sweep 顺序：x1span -> y1span -> gap -> x2span -> y2span。
data = library.phi_m1_data;
x1span = get_axis(data, 'x1span');
y1span = get_axis(data, 'y1span');
gap    = get_axis(data, 'gap');
x2span = get_axis(data, 'x2span');
y2span = get_axis(data, 'y2span');

% The array dimensions follow the Sweep tree: outer sweep first.
expected_size = [numel(x1span), numel(y1span), numel(gap), ...
                 numel(x2span), numel(y2span)];
assert(numel(phi_m1) == prod(expected_size), ...
    '结构库共有 %d 个相位数据，但 Sweep 参数应对应 %d 组结构。', ...
    numel(phi_m1), prod(expected_size));

[Lx1, Ly1, Gap, Lx2, Ly2] = ndgrid(x1span, y1span, gap, x2span, y2span);
phi_m1 = phi_m1(:);  phi_0 = phi_0(:);  phi_p1 = phi_p1(:);
Lx1 = Lx1(:);  Ly1 = Ly1(:);  Gap = Gap(:);
Lx2 = Lx2(:);  Ly2 = Ly2(:);

target_m1 = target.phiC_m1(:);
target_0  = target.phiC_0(:);
target_p1 = target.phiC_p1(:);
n_cells = numel(target_m1);

best_index = zeros(n_cells, 1);
best_cost = zeros(n_cells, 1);
for n = 1:n_cells
    cost = abs(exp(1i*phi_m1) - exp(1i*target_m1(n))).^2 + ...
           abs(exp(1i*phi_0)  - exp(1i*target_0(n))).^2  + ...
           abs(exp(1i*phi_p1) - exp(1i*target_p1(n))).^2;
    [best_cost(n), best_index(n)] = min(cost);
end

% 当前结构库固定 x1=-250 nm；x2 与 FDTD 的 gap 定义一致。
x1_fixed = -250e-9;
selected_Lx1 = Lx1(best_index);  selected_Ly1 = Ly1(best_index);
selected_gap = Gap(best_index);
selected_Lx2 = Lx2(best_index);  selected_Ly2 = Ly2(best_index);
selected_x2 = x1_fixed + selected_Lx1/2 + selected_gap + selected_Lx2/2;

Ny = size(target.phiC_m1, 1);
Nx = size(target.phiC_m1, 2);
matched = struct;
matched.index_map = reshape(best_index, Ny, Nx);
matched.cost_map = reshape(best_cost, Ny, Nx);
matched.Lx1_map_m = reshape(selected_Lx1, Ny, Nx);
matched.Ly1_map_m = reshape(selected_Ly1, Ny, Nx);
matched.gap_map_m = reshape(selected_gap, Ny, Nx);
matched.Lx2_map_m = reshape(selected_Lx2, Ny, Nx);
matched.Ly2_map_m = reshape(selected_Ly2, Ny, Nx);
matched.x2_map_m = reshape(selected_x2, Ny, Nx);

save(fullfile(this_dir, '905nm_phase_matched_structure_map.mat'), 'matched');

fprintf('相位匹配完成：%d 个超胞，平均评价函数 = %.4f。\n', ...
    n_cells, mean(best_cost));

function value = get_axis(data, name)
% 兼容 Lumerical 的 parameter 与 parameter_sweep 两种字段命名。
if isfield(data, name)
    value = data.(name)(:);
elseif isfield(data, [name '_sweep'])
    value = data.([name '_sweep'])(:);
else
    error('找不到参数轴：%s。', name);
end
end
