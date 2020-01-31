function rename_images(root_folder,src_subfolder,dst_subfolder,count,img_filename_tpl)
% 
% root_folder = '/home/ceres/Desktop/win_d/phpgedview/usbdisk_genealogia/RegistriAnagrafeCaposele/step10_san_Caposele/';
% src_subfolder = 'backup/Caposele_Restaurazione';
% dst_subfolder = 'Caposele_Restaurazione';
% count = 1009000;                % number of first image
% img_filename_tpl = 'A%07d.jpg'; % template for output images
% rename_images(root_folder,src_subfolder,dst_subfolder,count,img_filename_tpl)
% 


src_folder = [root_folder src_subfolder];
dst_folder = [root_folder dst_subfolder];

if ~exist(dst_folder,'dir')
    mkdir(dst_folder)
end

[path folder] = fileparts(src_folder);
z = regexp(folder,'[^_]+','match');
town = z{1};

z_info = load([src_folder filesep 'info_town']);
matr_files = z_info.webfolder_info.(town);

text_log     = '';
text_analisi = '';
for i_typology = 1:size(matr_files,1)
    typology_caption = matr_files{i_typology,1};
    typology_url     = matr_files{i_typology,2};
    typology_info    = matr_files{i_typology,3};
    
    webfolder_folder = typology_info.webfolder_folder;
    url_typology     = typology_info.url_typology;
    matr_years       = typology_info.matr_years;
    
    for i_year = 1:size(matr_years,1)
        year_caption = matr_years{i_year,1};
        year_url     = matr_years{i_year,2};
        year_info    = matr_years{i_year,3};
        
        % sort batches (so that '973, suppl. 2' comes after '973')    
        [temp_sort ind_sort] = sort(year_info(:,1));
        year_info = year_info(ind_sort,:);
        
        for i_batch = 1:size(year_info,1)
            batch_caption = year_info{i_batch,1};
            batch_url     = year_info{i_batch,2};
            batch_info    = year_info{i_batch,3};
            
            fprintf(1,'%s - %s - %s\n',typology_caption,year_caption,batch_caption);
            
            batch_fullfolder = batch_info.batch_folder; % es. '/home/ceres/StatoCivileSAN/Caposele_Napoleonico/Caposele_Nati_1815_975/'
            url_batch    = batch_info.url_batch;
            matr_stored  = batch_info.matr_stored;
            matr_stored  = batch_info.matr_stored;
            list_stored_filename = batch_info.list_stored_filename;
            matr_stored_cumul  = batch_info.matr_stored_cumul;
            
            batch_folder = remove_path(batch_fullfolder);
            
            text_log = sprintf('%s\n*** %s - %s - %s - %s\n',text_log,town,typology_caption,year_caption,batch_caption);
            
            batch_fullpath = [src_folder filesep batch_folder];
            ext = analise_batch(batch_folder,batch_fullpath,list_stored_filename,matr_stored_cumul);
            list_stored_filename_new = {};
            for i_img = 1:size(matr_stored,1)
                % for every downloaded image...
                img_id       = matr_stored{i_img,1};
                img_url      = matr_stored{i_img,2};
                img_fullname = list_stored_filename{i_img};
                
                img_filename = remove_path(img_fullname);
                img_filename_new  = sprintf(img_filename_tpl,count);
                img_fullname_old  = [src_folder filesep batch_folder filesep img_filename ext];
                img_fullname_new  = [dst_folder filesep img_filename_new];
                
                [flg_success,msg] = copyfile(img_fullname_old,img_fullname_new);
                flg_noatime = ~isempty(regexp(msg,'cp: preserving times for','once')); % copy done, but time was not changed (not actually important here)
                flg_ok = flg_success || flg_noatime;
%flg_ok=1;
                
                list_stored_filename_new{i_img} = img_filename_new; %#ok<AGROW>
                
                if ~flg_ok
                    fprintf(1,'*** Error copying file %s - %s\n',batch_folder,img_filename);
                    pause
                end
                
                count = count+1;
                text_log = sprintf('%s%3d) %20s -> %s  -  %s\n',text_log,img_id,img_filename,img_filename_new,img_url);
            end
            if ~isempty(list_stored_filename_new)
                ks_img_first = sprintf('DD MMM %s\t%s',year_caption,list_stored_filename_new{1});
                ks_img_last  = sprintf('DD MMM %s\t%s',year_caption,list_stored_filename_new{end});
                text_analisi = sprintf('%s\n%s\n%s\n%s\n',text_analisi,typology_caption,ks_img_first,ks_img_last);
            end
        end
    end
end

disp(text_log);
save_text(dst_folder,'img_rename_log.txt',text_log)

disp(text_analisi);
save_text(dst_folder,'analisi_log.txt',text_analisi)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_text(dst_folder,filename,txt)

filename_log = [dst_folder filesep filename];
fid = fopen(filename_log,'wt');
fprintf(fid,'%s',txt);
fclose(fid);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function filename = remove_path(fullname)

if (fullname(end) == filesep)
    fullname = fullname(1:end-1);
end

[temp filename] = fileparts(fullname);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ext flg_ok] = analise_batch(batch_folder,batch_fullpath,list_stored_filename,matr_stored_cumul)

flg_ok = 1;

z=regexp(list_stored_filename,'[^/]+$','match');
list_expected = [z{:}]';

if ( isempty(list_expected) && ~isempty(matr_stored_cumul) )
    % batch was already downloaded in the past, so it was not downloaded
    % this time (list_stored_filename is empty)
    ext = '';
    flg_ok = 1;
else
    % some images were downloaded, check that all expected ones are present
    % in the folder
    [temp temp ext] = fileparts(list_expected{1});
    
    z=dir([batch_fullpath filesep '*' ext]);
    [list_actual{1:length(z),1}] = deal(z.name);
    
    list_missing    = setdiff(list_expected,list_actual);
    list_unexpected = setdiff(list_actual,list_expected);
    
    if ~isempty(list_missing)
        flg_ok = 0;
        fprintf(1,'*** WARNING: following files are missing (%s):\n',batch_folder);
        disp(list_missing);
    end
    
    if ~isempty(list_unexpected)
        flg_ok = 0;
        fprintf(1,'*** WARNING: following files are unexpected (%s):\n',batch_folder);
        disp(list_unexpected);
    end
end

if ~flg_ok
    pause
end
