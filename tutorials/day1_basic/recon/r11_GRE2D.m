% Reconstruction of 2D Cartesian Pulseq data
% provides an example on how data reordering can be detected from the MR
% sequence with almost no additional prior knowledge
%
% needs mapVBVD in the path
clear all;close all;clc
%% Load data sorted by name
path = pwd ; % directory to be scanned for data files
nF = 1 ; % the number of the file / data set to load

pattern='*s11*.dat';
D=dir([path filesep pattern]) ;
[~,I]=sort(string({D(:).name})) ;
data_file_path=[path filesep D(I(nF)).name] ;

%% Load the file from a dir
twix_obj = mapVBVD(data_file_path);

%% Load sequence from file (optional, you may still have it in memory)
seq_file_path = 's11_gre.seq';

[~,out_name,~] = fileparts(seq_file_path); 

seq = mr.Sequence() ;              % Create a new sequence object
seq.read(seq_file_path,'detectRFuse') ;

[ktraj_adc, t_adc, ktraj, t_ktraj, t_excitation, t_refocusing] = seq.calculateKspacePP();
figure; plot(ktraj(1,:),ktraj(2,:),'b',...
             ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % a 2D plot
axis('equal');
title('k-space');
xlabel('kx / m^-^1') ; 
ylabel('kx / m^-^1') ; 
exportgraphics(gcf,'s11_k-space.png',...
    'ContentType','vector',...
    'BackgroundColor','none') ;

%% Analyze the trajectory data (ktraj_adc)
k_extent = max(abs(ktraj_adc),[],2) ;
k_scale = max(k_extent) ;
k_threshold = k_scale/5000 ;

% detect unused dimensions and delete them
if any(k_extent<k_threshold)
    ktraj_adc(k_extent<k_threshold,:)=[]; % delete rows
    k_extent(k_extent<k_threshold)=[];
end

% detect dK, k-space reordering and repetitions (or slices, etc)
kt_sorted=sort(ktraj_adc,2);
dk_all=kt_sorted(:,2:end)-kt_sorted(:,1:(end-1));
dk_all(dk_all<k_threshold)=NaN;
dk_min=min(dk_all,[],2);
dk_max=max(dk_all,[],2);
dk_all(dk_all-dk_min(:,ones(1,size(dk_all,2)))>k_threshold)=NaN;
dk_all_cnt=sum(isfinite(dk_all),2);
dk_all(~isfinite(dk_all))=0;
dk=sum(dk_all,2)./dk_all_cnt;
[~,k0_ind]=min(sum(ktraj_adc.^2,1));
kindex=round((ktraj_adc-ktraj_adc(:,k0_ind*ones(1,size(ktraj_adc,2))))./dk(:,ones(1,size(ktraj_adc,2))));
kindex_min=min(kindex,[],2);
kindex_mat=kindex-kindex_min(:,ones(1,size(ktraj_adc,2)))+1;
kindex_end=max(kindex_mat,[],2);
sampler=zeros(kindex_end');
repeat=zeros(1,size(ktraj_adc,2));
for i=1:size(kindex_mat,2)
    if (size(kindex_mat,1)==3)
        ind=sub2ind(kindex_end,kindex_mat(1,i),kindex_mat(2,i),kindex_mat(3,i));
    else
        ind=sub2ind(kindex_end,kindex_mat(1,i),kindex_mat(2,i)); 
    end
    repeat(i)=sampler(ind);
    sampler(ind)=repeat(i)+1;
end
if (max(repeat(:))>0)
    kindex=[kindex;(repeat+1)];
    kindex_mat=[kindex_mat;(repeat+1)];
    kindex_end=max(kindex_mat,[],2);
end

%% sort in the k-space data
if iscell(twix_obj)
    data_unsorted = twix_obj{end}.image.unsorted();
else
    data_unsorted = twix_obj.image.unsorted();
end

% the incoming data order is [kx coils acquisitions]
data_coils_last = permute(data_unsorted, [1, 3, 2]);
nCoils = size(data_coils_last, 3);

data_coils_last=reshape(data_coils_last, [size(data_coils_last,1)*size(data_coils_last,2), nCoils]) ;

data = zeros([kindex_end' nCoils]) ;
if (size(kindex,1)==3)
    for i=1:size(kindex,2)
        data(kindex_mat(1,i),kindex_mat(2,i),kindex_mat(3,i),:) = data_coils_last(i,:) ;
    end
else
    for i=1:size(kindex,2)
        data(kindex_mat(1,i),kindex_mat(2,i),:) = data_coils_last(i,:) ;
    end
end

if size(kindex,1) == 3
    nImages = size(data,3) ;
else
    nImages = 1 ;
    data=reshape(data, [size(data,1) size(data,2) 1 size(data,3)]) ;
end

%% Reconstruct coil images

images = zeros(size(data)) ;
for ii = 1:nCoils
    images(:,:,:,ii) = fftshift(fft2(fftshift(data(end:-1:1,:,:,ii)))) ;
end

%% Image display with optional sum of squares combination
figure ;
if nCoils>1
    sos=abs(sum(images.*conj(images),ndims(images))).^(1/2) ;
    sos=sos./max(sos(:)) ;    
    imshow(rot90(sos),[]) ;
else
    imab(abs(images));
end
colormap('default') ;
exportgraphics(gcf,'s11_im.png',...
    'ContentType','vector',...
    'BackgroundColor','none') ;
