% find centers simple
% initial slice alignment based on finding centers
function find_centers_for_initialization_nissl(target_dir,output_dir,down)
% clear all;
% close all;
% fclose all;
% addpath /cis/home/dtward/Functions/plotting
% addpath /cis/home/dtward/Functions/downsample
% local
% keyboard
addpath Functions/plotting
addpath Functions/downsample
if nargin < 3
    down = 3*4;
end


%%
% target_dir = '/cis/home/dtward/Documents/intensity_transform_and_missing_data/csh_slices/toDaniel/MD710/';
% target_dir = '/cis/home/dtward/Documents/intensity_transform_and_missing_data/csh_slices/toDaniel/MD705/';
% target_dir = '/cis/home/dtward/Documents/intensity_transform_and_missing_data/csh_slices/toDaniel/MD711/';
geometry_file = dir([target_dir '*.csv']);
fid = fopen([target_dir geometry_file(1).name],'rt');
line = fgetl(fid); % ignore the first line
% it should say
% filename, nx, ny, nz, dx, dy, dz, x0, y0, z0

csv_data = {};
count = 0;
while 1
    line = fgetl(fid);
    if line == -1
        break
    end
    count = count + 1;
    % process this line, splitting at commas
    csv_data(count,:) = strsplit(line,',');
    %     
end
fclose(fid);
files = csv_data(:,1);
nxJ0 = cellfun(@(x)str2num(x), csv_data(:,2:3));
dxJ0 = cellfun(@(x)str2num(x), csv_data(:,5:6));
zJ0 = cellfun(@(x)str2num(x), csv_data(:,10));
isthicks = cellfun(@(x) str2num(x), csv_data(:,7)) > 20;





AJ = zeros(3,3,length(files));
% load and downsample
for i = 1 : length(files)
    disp(['downsampling ' num2str(i) ' of ' num2str(length(files))])
    I_ = imread([target_dir files{i}]);
    W_ = double(~(I_(:,:,1) == 255 & I_(:,:,2) == 255 & I_(:,:,3) == 255));
    I_ = double(I_)/255.0;
    [~,~,Wd_] = downsample2D(1:size(I_,2),1:size(I_,1),W_,down*[1,1]);
    Id_ = zeros(size(Wd_,1),size(Wd_,2),3);
    for c = 1 : 3
        [~,~,Id_(:,:,c)] = downsample2D(1:size(I_,2),1:size(I_,1),I_(:,:,c),down*[1,1]);
    end
    
%     Isave{i} = Id_;
%     Wsave{i} = Wd_;

%%
% find centers
%     I = Isave{i};
%     W = Wsave{i};
    I = Id_;
    W = Wd_;
    % hopefully avoid artifacts near edges
    buf = 5;
    W(1:buf,:) = 0;
    W(end-buf+1:end,:) = 0;
    W(:,1:buf) = 0;
    W(:,end-buf+1:end) = 0;
    x = (0 : size(I,2)-1)*dxJ0(i,1)*down;
    y = (0 : size(I,1)-1)*dxJ0(i,2)*down;
    x = x - mean(x);
    y = y - mean(y);
    [X,Y] = meshgrid(x,y);
    
    % 
    danfigure(1);
    imagesc(x,y,I)
    axis image
    
    % we want to find the center of mass in some sense
    for c = 1 : 3
        %         themax(c) = max(max(I(:,:,c).*(W==1)));
        tmp = I(:,:,c).*(W==1);
%         themax(c) = max(tmp(:));
        themax(c) = quantile(tmp(:),0.95);
    end
    test = mean(bsxfun(@minus, reshape(themax,[1,1,3]),I),3);
    test(test < 0) = 0;
    
    % any spatial prior?
%     W = W.*exp(-1/2*(X.^2 + Y.^2)/5000^2);
    I0 = sum(test(:).*W(:));
    test = test/I0;
    Ix = sum(test(:).*X(:).*W(:));
    Iy = sum(test(:).*Y(:).*W(:));
    hold on;
    scatter(Ix,Iy,100,'f','k');
    hold off;
    drawnow
    
    AJ(:,:,i) = eye(3);
    AJ(1:2,3,i) = [Ix,Iy];
    
    
end
%%
% save(['721_initializer_A.mat'],'AJ');
% save([target_dir 'initializer_A.mat'],'AJ');
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end
save([output_dir 'initializer_A.mat'],'AJ');

% there is a problem where these guys are not zero mean
% this will be dealt with in the mapping script