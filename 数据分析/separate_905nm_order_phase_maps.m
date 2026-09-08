clear; clc;

this_dir = fileparts(mfilename('fullpath'));
input_file = fullfile(this_dir,'T_nearfield_905nm.mat');
output_file = fullfile(this_dir,'T_order_phase_maps_905nm.mat');
figure_file = fullfile(this_dir,'T_order_phase_maps_905nm.png');

S = load(input_file,'Edata');
Edata = S.Edata;
x = Edata.x(:);
y = Edata.y(:);
Ex = squeeze(Edata.E(:,:,1,1,1)).';

Ny = numel(y);
Nx = numel(x);
assert(isequal(size(Ex),[Ny,Nx]),'Unexpected Edata.E dimensions.');
dx = mean(diff(x));
dy = mean(diff(y));
assert(max(abs(diff(x)-dx)) < 1e-12 && max(abs(diff(y)-dy)) < 1e-12, ...
    'The monitor grid must be uniform.');

Sx = 1350e-9;
filter_radius = 0.7*pi/Sx;
orders = [-1,0,1];

kx = 2*pi*(-floor(Nx/2):ceil(Nx/2)-1)/(Nx*dx);
ky = 2*pi*(-floor(Ny/2):ceil(Ny/2)-1)/(Ny*dy);
[KX,KY] = meshgrid(kx,ky);
[X,~] = meshgrid(x,y);
F = fftshift(fft2(Ex));

phase_maps = zeros(Ny,Nx,3);
amplitude_maps = zeros(Ny,Nx,3);
complex_envelopes = zeros(Ny,Nx,3);

for q = 1:3
    kx_order = orders(q)*2*pi/Sx;
    spectral_mask = (KX-kx_order).^2 + KY.^2 <= filter_radius^2;
    order_field = ifft2(ifftshift(F.*spectral_mask));
    envelope = order_field.*exp(-1i*kx_order*X);
    amplitude = abs(envelope);
    phase = mod(angle(envelope),2*pi);
    phase(amplitude < 0.05*max(amplitude(:))) = NaN;
    phase_maps(:,:,q) = phase;
    amplitude_maps(:,:,q) = amplitude;
    complex_envelopes(:,:,q) = envelope;
end

figure('Color','w','Position',[100,100,1350,420]);
for q = 1:3
    subplot(1,3,q);
    imagesc(x*1e6,y*1e6,phase_maps(:,:,q));
    axis image xy;
    caxis([0,2*pi]);
    colorbar;
    xlabel('x [um]');
    ylabel('y [um]');
    title(sprintf('Order N = %d phase [rad]',orders(q)));
end
exportgraphics(gcf,figure_file,'Resolution',300);

save(output_file,'x','y','orders','filter_radius','phase_maps', ...
    'amplitude_maps','complex_envelopes');
