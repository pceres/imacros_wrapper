function result = san(action,params)
%
% result = san(action,params)
%
% % es.:
%
% % download a complete batch (eg Caposele Nati 1818, busta 978)
% result = san('dnld_batch',{'http://www.antenati.san.beniculturali.it/v/Archivio+di+Stato+di+Salerno/Stato+civile+della+restaurazione/Caposeleprovincia+di+Avellino/Nati/1818/978/','/home/ceres/StatoCivileSAN/Caposele_Restaurazione/','Caposele_Nati_1818_978','978'}) % plain batch
% result = san('dnld_batch',{'http://www.antenati.san.beniculturali.it/v/Archivio+di+Stato+di+Salerno/Stato+civile+della+restaurazione/Caposeleprovincia+di+Avellino/Nati/1827/988/','/home/ceres/StatoCivileSAN/Caposele_Restaurazione/','Caposele_Nati_1827_988','988'}) % some images are not available (dummy images: 3, 5)
% result = san('dnld_batch',{'http://www.antenati.san.beniculturali.it/v/Archivio+di+Stato+di+Salerno/Stato+civile+della+restaurazione/Valvaoggi+Salerno/Matrimoni+processetti/1855/6484/','/home/ceres/StatoCivileSAN/Valva_Restaurazione/','Valva_MatrimoniProcessetti_1855_6484','6484'}) % subbatch (first part of image name) is not the same for all batch images
% 
% % download a whole typology (eg Caposele Nati (all years) )
% result = san('dnld_typology',{'http://www.antenati.san.beniculturali.it/v/Archivio+di+Stato+di+Salerno/Stato+civile+della+restaurazione/Caposeleprovincia+di+Avellino/Matrimoni+processetti/','/home/ceres/StatoCivileSAN/Caposele_Restaurazione/','Caposele_MatrimoniProcessetti','Matrimoni, processetti'})
%
% % download a whole town (eg Caposele (Nati, Morti, Matrimoni, etc.) )
% result = san('dnld_town',{'http://www.antenati.san.beniculturali.it/v/Archivio+di+Stato+di+Salerno/Stato+civile+della+restaurazione/Caposeleprovincia+di+Avellino/','/home/ceres/StatoCivileSAN/Caposele_Restaurazione/','Caposele','Caposele(provincia di Avellino)'})
%
% err_code:
%   1: problems with iMacros_wrapper
%   2: problems accessing web page
%   3: Error accessing url for tipology %s: %s
%
%

switch action
    case 'dnld_batch'
        result = dnld_batch(params);
    case 'dnld_typology'
        result = dnld_typology(params);
    case 'dnld_town'
        result = dnld_town(params);
    otherwise
        error('Unknown action %s',action)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = dnld_town(params)

err_code = 0;
err_msg  = '';
matr_typology = {};

flg_dnld = 1; % 0 --> just list, disable download

str = extract_params(params,{'url_town','folder_root','folder_town','tag_town'});
url_town    = str.url_town;     % url
folder_root = str.folder_root;  % folder root where folder_town will be created
folder_town = str.folder_town;  % folder prefix for downloaded images
tag_town    = str.tag_town;     % title of the page

webfolder_folder = folder_root;
create_folder_if_needed(webfolder_folder);

result0 = configure_iw();
if (result0.err_code ~= 0)
    err_code = 1;
    err_msg  = 'problems with iMacros_wrapper';
else
    % get typology info (available years, etc.)
    result0 = detect_webfolder_info(url_town,tag_town,webfolder_folder,'info_town.mat');
    if (result0.err_code ~= 0)
        err_code = 3;
        err_msg  = sprintf('Error accessing url for tipology %s: %s',tag_town,url_town);
    else
        matr_typology   = result0.matr_items;
        info_fullname   = result0.info_fullname;
        
        fprintf(1,'Found %d typologies:\n',size(matr_typology,1))
        disp(matr_typology(:,1))
        
        for i_item = 1:size(matr_typology,1)
            tag_typology = matr_typology{i_item,1};
            url_typology = matr_typology{i_item,2};
            
            if flg_dnld
                folder_typology = [folder_town '_' prepare_tag(tag_typology)];
                result0 = san('dnld_typology',{url_typology,folder_root,folder_typology,tag_typology});
                result_typology = result0.result_webfolder;
            else
                result_typology = {}; %#ok<UNRCH>
            end

            matr_typology{i_item,3} = result_typology; %matr_years;
            
            % save updated info
            save_webfolder_info(info_fullname,tag_town,matr_typology)
        end
        
        % detect typologies that were not downloaded
        v_empty = cellfun('isempty',matr_typology(:,3));
        if any(v_empty)
            fprintf(1,'\nTypologies that were not downloaded:\n')
            disp(matr_typology(v_empty,1))
        else
            disp('All tipologies downloaded correctly')
        end
        
        % final report
        show_town_report(matr_typology)
    end
end

result_webfolder = struct();
result_webfolder.webfolder_folder   = webfolder_folder;
result_webfolder.url_town           = url_town;
result_webfolder.matr_typology      = matr_typology;

result = struct();
result.err_code         = err_code;
result.err_msg          = err_msg;
result.result_webfolder = result_webfolder;   % info on typology



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = dnld_typology(params)

err_code = 0;
err_msg  = '';
matr_years = {};

flg_dnld = 1; % 0 --> just list, disable download

str = extract_params(params,{'url_typology','folder_root','folder_typology','tag_typology'});
url_typology    = str.url_typology;     % url
folder_root     = str.folder_root;      % folder root where folder_typology will be created
folder_typology = str.folder_typology;  % folder prefix for downloaded images
tag_typology    = str.tag_typology;     % title of the page

webfolder_folder = folder_root;
create_folder_if_needed(webfolder_folder);

result0 = configure_iw();
if (result0.err_code ~= 0)
    err_code = 1;
    err_msg  = 'problems with iMacros_wrapper';
else
    % get typology info (available years, etc.)
    result0 = detect_webfolder_info(url_typology,tag_typology,webfolder_folder,'info_typology.mat');
    if (result0.err_code ~= 0)
        err_code = 3;
        err_msg  = sprintf('Error accessing url for tipology %s: %s',tag_typology,url_typology);
    else
        matr_years    = result0.matr_items;
        info_fullname = result0.info_fullname;
        
        fprintf(1,'Found %d years for typology "%s":\n',size(matr_years,1),tag_typology)
        disp(matr_years(:,1))
        
        for i_year = 1:size(matr_years,1)
            tag_year = matr_years{i_year,1};
            url_year = matr_years{i_year,2};
            
            % get year info (available batches, etc.)
            matr_buste = detect_year_info(matr_years,url_year,tag_year);
            for i_busta = 1:size(matr_buste,1)
                tag_busta = matr_buste{i_busta,1};
                url_busta = matr_buste{i_busta,2};
                
                if flg_dnld
                    folder_batch = [folder_typology '_' prepare_folder(tag_year) '_' prepare_folder(tag_busta)];
                    result0 = san('dnld_batch',{url_busta,folder_root,folder_batch,tag_busta});
                    result_batch = result0.result_batch;
                else
                    result_batch = []; %#ok<UNRCH>
                end
                
                matr_buste{i_busta,3} = result_batch;
                
                fprintf(1,'Year %s, busta %s completed: %s\n',tag_year,tag_busta,url_busta)
            end
            
            matr_years{i_year,3} = matr_buste;
            
            % save updated info
            save_webfolder_info(info_fullname,tag_typology,matr_years);
        end
        
        % detect years that were not downloaded
        v_empty = cellfun('isempty',matr_years(:,3));
        if any(v_empty)
            fprintf(1,'\nYears that were not downloaded:\n')
            disp(matr_years(v_empty,1))
        else
            disp('All years downloaded correctly')
        end
        
        % final report
        show_typology_report(matr_years);
    end
end

result_webfolder = struct();
result_webfolder.webfolder_folder   = webfolder_folder;
result_webfolder.url_typology       = url_typology;
result_webfolder.matr_years         = matr_years;

result = struct();
result.err_code = err_code;
result.err_msg = err_msg;
result.result_webfolder = result_webfolder;   % info on typology



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = dnld_batch(params)

err_code = 0;
err_msg = '';
result_batch = struct();

special_string = '$££$';

str = extract_params(params,{'url_batch','folder_root','folder_batch','tag_batch'});
url_batch    = str.url_batch;   % url of the batch to be downloaded
folder_root  = str.folder_root; % root folder where folder_batch will be created
folder_batch = str.folder_batch;% folder containing downloaded images
tag_batch    = str.tag_batch;   % tag of the web page to be checked before proceeding with download

result0 = configure_iw();
if (result0.err_code ~= 0)
    err_code = 1;
    err_msg  = 'problems with iMacros_wrapper';
else
    % get batch info (number of images, etc.)
    result0 = detect_batch_info(url_batch,tag_batch,folder_root,folder_batch,special_string);
    if (result0.err_code ~= 0)
        err_code = 2;
        err_msg  = sprintf('problems accessing batch info from web page %s',url_batch);
    else
        %num_img              = result0.num_img;
        num_figures          = result0.num_figures;
        %url_img_template     = result0.url_img_template;
        batch_folder         = result0.batch_folder;
        matr_img_to_dnld_ref = result0.matr_img; % matrix with list of all images in batch (numeric id in col1, url in col2)

        % detect images to be downloaded
        matr_img_to_dnld = detect_images_to_download(batch_folder,matr_img_to_dnld_ref);
        
        % loop to download images in the batch
        [list_stored list_stored_filename list_dummy_filename] = download_batch_loop(matr_img_to_dnld,matr_img_to_dnld_ref,batch_folder,num_figures);
        matr_stored = list_to_matr(matr_img_to_dnld_ref,list_stored);
        
        fprintf(1,'Batch %s was downloaded.\n',folder_batch);
        
        result_batch = struct();
        result_batch.batch_folder = batch_folder;     % fullname of folder containing images
        result_batch.url_batch    = url_batch;        % url of batch
        result_batch.matr_stored  = matr_stored;      % matr of downloaded images (col1: numeric id as shown in batch page, col2: url)
        result_batch.list_stored_filename = list_stored_filename;   % filenames of downloaded images
        result_batch.list_dummy_filename = list_dummy_filename;     % filenames of missing images (not available in website)
    end
end

result = struct();
result.err_code = err_code;
result.err_msg = err_msg;
result.result_batch = result_batch;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_buste = detect_year_info(matr_items,url_item,tag_item)

ind_item = strmatch(tag_item,matr_items(:,1),'exact');
if ( (size(matr_items,2) > 2) && ~isempty(matr_items{ind_item,3}) )
    % use local info on available batches
    matr_buste = matr_items{ind_item,3};
else
    % get info from web page
    result0 = open_batch_page('go_image',url_item,tag_item,tag_item,{});
    if (result0.err_code ~= 0)
        % could not open url for year
        fprintf(1,'Error accessing url for item %s: %s\n',tag_item,url_item);
        matr_buste = {};
    else
        z=regexp(result0.text,'giTitle">[\r\n]+<a href="([^"]+?)"','tokens');
        list_url_buste = [z{:}]';
        z=regexp(result0.text,'giTitle">[\r\n].*?">[\r\n]+([^<]+)<','tokens');
        list_buste = [z{:}]';
        
        matr_buste = [list_buste list_url_buste];
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = detect_webfolder_info(url_webfolder,tag_webfolder,webfolder_folder,info_matfile)
% get webfolder info (available items and corresponding url)

err_code = 0;
err_msg  = '';

info_fullname = [webfolder_folder info_matfile];
[webfolder_info matr_items] = load_webfolder_info(info_fullname,tag_webfolder);

if ( isempty(matr_items) )
    result0 = open_batch_page('go_image',url_webfolder,tag_webfolder,tag_webfolder,{});
    z = regexp(result0.text,'giTitle">[\r\n]+<a href="([^"]+?)"','tokens');
    if isempty(z)
        err_code = 3;
        err_msg  = sprintf('Error accessing url for webfolder %s: %s',tag_webfolder,url_webfolder);
    else
        list_url = [z{:}]';
        
        z=regexp(result0.text,'giTitle">[\r\n].*?">[\r\n]+([^<]+)<','tokens');
        list_items = [z{:}]';
        
        matr_items = [list_items list_url];
        
        % save detected info
        save_webfolder_info(info_fullname,tag_webfolder,matr_items);
    end
end

result = struct();
result.err_code         = err_code;
result.err_msg          = err_msg;
result.matr_items       = matr_items;
result.info_fullname    = info_fullname;
result.url_webfolder    = url_webfolder;
result.webfolder_folder = webfolder_folder;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function show_typology_report(matr_years)

v_status = {};
for i_year = 1:size(matr_years,1)
    matr_year = matr_years{i_year,3};
    
    for i_batch = 1:size(matr_year,1)
        str=matr_year{i_batch,3};
        
        z=regexp(str.list_dummy_filename,'([0-9]+)\.','tokens');
        z3=[z{:}]';
        if isempty(z3)
            ks_missing = '';
        else
            list_missing_id = str2double([z3{:}]');
            ks_missing = num2str(list_missing_id','%d,');
            ks_missing = ks_missing(1:end-1);
        end
        
        if isempty(str)
            msg='*** ';
            ks_year='???';
        else
            [tmp, ks_year] = fileparts(str.batch_folder(1:end-1));
            if ~isempty(str.list_dummy_filename)
                msg='!!! ';
            else
                msg='    ';
            end
        end
        v_status{end+1} = msg; %#ok<AGROW>
        fprintf(1,'%s%s\t%s\n',msg,ks_year,ks_missing);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function show_town_report(matr_typology)

fprintf(1,'\ndnld_town report. Attempted downloads:\n');

v_status = {};
for i_typology = 1:size(matr_typology,1)
    ks_typology = matr_typology{i_typology,1};
    str         = matr_typology{i_typology,3};
    
    if isempty(str)
        msg='*** ';
    else
        msg='    ';
    end
    v_status{end+1} = msg; %#ok<AGROW>
    fprintf(1,'%s%s\n',msg,ks_typology);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = configure_iw()

err_code = 0;
err_msg  = '';

flg_clear_cookies = 0;

st = dbstack;
[list_fcn{1:length(st)}] = deal(st.name);
if ( length(strmatch('san',list_fcn,'exact'))==1 )
    % this is the first call, so onfiguring is needed
    result = iw('write_cmd',{'set_param',struct('dump_type','HTM')}); % requires dump of web pages in html format
    if (result.err_code ~= 0)
        err_code = 1;
        err_msg  = 'problems with iMacros_wrapper';
    else
        % additional configuration to clear
        if flg_clear_cookies
            result = iw('write_cmd',{'set_param',struct('flg_clear','1')}); %#ok<UNRCH> % clear all cookies, for performance reasons
            if (result.err_code ~= 0)
                err_code = 1;
                err_msg  = 'problems with iMacros_wrapper';
            end
        end
    end
else
    % nested call: repeating configuration is not needed
end

result = struct();
result.err_code = err_code;
result.err_msg = err_msg;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = detect_batch_info(url_batch,tag_batch,folder_root,folder_batch,special_string)

err_code = 0;
err_msg  = '';
matr_img = {};

info_matfile = 'info.mat';

batch_folder = [folder_root folder_batch filesep];
create_folder_if_needed(folder_root);
create_folder_if_needed(batch_folder);

info_fullname = [batch_folder info_matfile];
flg_fast_result = 0; % 0 --> need to visit website; 1 --> info is already available
if exist(info_fullname,'file')
    z = load(info_fullname);
    if isfield(z,'batch_info') && isfield(z.batch_info,'matr_img')
        batch_info = z.batch_info;
        num_img             = batch_info.num_img;
        num_figures         = batch_info.num_figures;
        url_img_template    = batch_info.url_img_template;
        matr_img            = batch_info.matr_img; ...
        %batch_folder        = batch_info.batch_folder; % don't take the original one, as the folder could have been removed
        flg_fast_result = 1;
    else
        fprintf(1,'Batch info is present in %s, but has an obsolete format. Rebuilding...\n',folder_batch)
    end
end

if ( ~flg_fast_result )
    batch_page = 1;
    result0 = open_batch_page('go_batch',url_batch,'',tag_batch,{batch_page});
    if (result0.err_code ~= 0)
        err_code = 2;
        err_msg  = sprintf('problems accessing web page %s',url_batch);
    else
        text_batch_first = result0.text;
        z = regexp(text_batch_first,'href="([^"]*)">\s*Immagine 1[^0-9]','tokens');
        url_img1 = z{1}{1};
        z2_first = regexp(url_img1,'([0-9]+)_([0-9]+)\.jpg.html','tokens');
        sub_batch_first = z2_first{1}{1}; % magic id for the batch images (it is usually the same for all images, but there are exceptions, i.e. Valva Restaurazione Processetti 1855)
        %ks_num_img      = z2_first{1}{2}; % of course id is 1!
        
        % view image 1
        result0 = open_batch_page('go_image',url_img1,'Immagine<SP>1','Immagine 1',{});
        result0_text = result0.text;
        
        z=regexp(result0_text,'href="([^"]*)" class="last"','match');
        imglast=z{1}; % piece of anchor tag containing last image url
        z2_last = regexp(imglast,'([0-9]+)_([0-9]+)\.jpg.html','tokens');
        sub_batch_last  = z2_last{1}{1};
        ks_num_img      = z2_last{1}{2};
        
        num_figures = length(ks_num_img); % number of figures in image number format
        num_img = str2double(ks_num_img); % number of images to be downloaded
        z2 = regexp(imglast,'href="([^"]*)"','tokens');
        url_img_template = regexprep(z2{1}{1},['_' ks_num_img '\.jpg.html'],['_' special_string '\.jpg.html']);
         
        %% detetct list of all images in batch
        if ~strcmp(sub_batch_first,sub_batch_last)
            % there is more than one single subbatch for the batch: it is
            % needed to detect url for each image
            disp('Multiple subbatch detected: complete url listing is needed...')
            result0 = get_img_list(text_batch_first,tag_batch,batch_folder);
        else
            % all images are in the same subbatch, the list can be created
            % easily
            matr_img = {};
            for i_img = 1:num_img
                num_figures = length(ks_num_img); % number of figures in image number format
                img_tag = sprintf(['%0' num2str(num_figures) 'd'],i_img);
                url_img = strrep(url_img_template,special_string,img_tag);
                matr_img(end+1,:) = {i_img, url_img}; %#ok<AGROW>
            end
                
            result0.err_code = 0;
            result0.err_msg  = '';
            result0.matr_img = matr_img;
        end
        
        %% manage batch error detection
        if (result0.err_code ~= 0)
            err_code = result0.err_code;
            err_msg  = result0.err_msg;
        else
            matr_img = result0.matr_img; % col1: img id, col2: img url
        end
    end
    
    %% save info if there is no error
    if (err_code == 0)
        % save detected info
        batch_info = struct( ...
            'num_img',          num_img, ...
            'num_figures',      num_figures, ...
            'url_img_template', url_img_template, ...
            'matr_img',         {matr_img}, ...
            'batch_folder',     batch_folder ...
            ); %#ok<NASGU> % used in save command
        save(info_fullname,'batch_info')
    end
end

result = struct();
result.err_code         = err_code;
result.err_msg          = err_msg;

result.num_img          = num_img;
result.num_figures      = num_figures;
result.url_img_template = url_img_template;
result.batch_folder     = batch_folder;
result.matr_img         = matr_img;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = get_img_list(text_batch_first,tag_batch,batch_folder)

err_code = 0;
err_msg  = '';
matr_img = {};

text_batch = text_batch_first;

ancora = 1;
while ancora
    z = regexp(text_batch,'Immagine ([0-9]+).*?href="([^"]*)">\s*Immagine [0-9]+','tokens');
    matr_img0 = reshape([z{:}],2,length(z))';
    matr_img0(:,1) = num2cell(str2double(matr_img0(:,1))); % first column has numerical id of image, second column has img url
    matr_img = [matr_img;matr_img0]; %#ok<AGROW>
    z = regexp(text_batch,'href="([^"]*)"[^>]*>successivo','tokens');
    if isempty(z)
        text_batch = '';
        ancora = 0;
    else
        url_batch_next = z{1}{1};
        z=regexp(url_batch_next,'g2_page=([0-9]+)&','tokens');
        expected_batch_page = str2double(z{1}{1});
        result0 = open_batch_page('go_batch',url_batch_next,'',tag_batch,{expected_batch_page});
        if (result0.err_code ~= 0)
            err_code = result0.err_code;
            err_msg  = result0.err_msg;
            break;
        end
        text_batch = result0.text;
        ancora = 1;
    end
end

%% check for dummy images
v = diff(cell2mat(matr_img(:,1)));
v_ = unique(v);
if ( (length(v_)>1) || (v_(1) ~= 1) )
    % dummy images detected
    ind_gap = find(v~=1)+1;
    matr_dummy = matr_img(ind_gap,:);
    matr_dummy(:,1) = num2cell(cell2mat(matr_dummy(:,1))-1);
    for i_dummy = 1:size(matr_dummy,1)
        img_id  = matr_dummy{i_dummy,1};
        img_url = matr_dummy{i_dummy,2};
        
        z = regexp(img_url, '/([0-9]+_[0-9]+\.jpg)\.html', 'tokens');
        img_filename = z{1}{1};
        
        z = regexp(img_filename, '_([0-9]+)\.', 'tokens');
        ks_id = z{1}{1};
        num_figures = length(ks_id);
        
        img_tag = sprintf(['%0' num2str(num_figures) 'd'],img_id);
        img_filename_dummy = [regexprep(img_filename,['_' ks_id '\.'],['_' img_tag '\.']) '.missing.txt'];
        ing_fullname_dummy = [batch_folder img_filename_dummy];
        
        % create dummy file to mark the fact that image is not available
        fid = fopen(ing_fullname_dummy,'w+');
        fclose(fid);
        
        fprintf(1,'\tCreated dummy image %s\n',img_filename_dummy)
    end
end

result = struct();
result.err_code = err_code;
result.err_msg  = err_msg;
result.matr_img = matr_img; % each row has format {img_id, img_url}, with img_id as an integer



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [list_stored list_stored_filename list_dummy_filename] = download_batch_loop(matr_img_to_dnld,matr_img_to_dnld_ref,batch_folder,num_figures)

max_img_retries = 3; % number of attempts to download an image

result = iw('iMacros_rootfolder',{});
imacros_root = result.folder;
imacros_download = [imacros_root 'Downloads' filesep];
dnld_file = [imacros_download 'main.php'];

flg_do_check = 1;
if isempty(matr_img_to_dnld)
    % no other image to be downloaded
    [matr_id, list_stored list_stored_filename list_dummy_filename] = detect_images_to_download(batch_folder,matr_img_to_dnld_ref);
    list_multiple = check_multiple_images(list_stored,list_stored_filename,matr_img_to_dnld_ref);
    if isempty(list_multiple)
        flg_do_check = 0;
    end
end

%% complete check
if flg_do_check
    ancora = 1;
    while ancora
        for i_pos = 1:size(matr_img_to_dnld,1)
            i_img   = matr_img_to_dnld{i_pos,1};
            url_img = matr_img_to_dnld{i_pos,2};
            
            ancora_img = 1;
            count_img = 0;
            while ancora_img
                flg_ok = download_img(i_img,url_img,dnld_file,batch_folder,num_figures);
                ancora_img = (flg_ok==0) && (count_img<max_img_retries);
                count_img = count_img+1;
            end
        end
        
        % check for wrong or multiple images
        [matr_id_check list_stored list_stored_filename list_dummy_filename] = detect_images_to_download(batch_folder,matr_img_to_dnld_ref);
        list_id_check = cell2mat(matr_id_check(:,1));
        list_multiple = check_multiple_images(list_stored,list_stored_filename,matr_img_to_dnld_ref);
        if ( size(list_multiple,1)>0 )
            % multiple images detected
            list_id_multiple = [];
            for i_multiple = 1:size(list_multiple,1);
                list_id_multiple = [list_id_multiple; list_multiple{i_multiple,2}]; %#ok<AGROW>
            end
            matr_id_multiple = list_to_matr(matr_img_to_dnld_ref,list_id_multiple);
            disp('Multiple images detected:')
            disp(list_id_multiple);
        else
            matr_id_multiple = {};
        end
        matr_img_to_dnld = [matr_id_check; matr_id_multiple];    % multiple images were deleted, so they need to be downloaded again
        
        % remove duplicates
        [temp, ind] = unique(cell2mat(matr_img_to_dnld(:,1)));
        matr_img_to_dnld = matr_img_to_dnld(ind,:);
        
        ancora = ~isempty(list_multiple) || ~isempty(list_id_check);
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function matr_id = list_to_matr(matr_img_ref,list_id)

matr_id = {};
for i_img = 1:length(list_id);
    img_id = list_id(i_img);
    ind = cell2mat(matr_img_ref(:,1))==img_id;
    matr_id(end+1,:) = matr_img_ref(ind,:); %#ok<AGROW>
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = open_batch_page(imacro,url_batch,page_title,tag_batch,params)
% imacro        name of macro to be called {'go_image','go_batch'}
% url_batch     url to be displayed
% page_title    name of page title to be checked by macro
% tag_batch     name of H1 html title in the page
%
% err_code:
% 0: No error
% 1: Error opening the web page
% 2: Image is missing from website


% default return struct, in case it is not rewritten by the correct
% return value for the downloaded page
result = struct();
result.err_code = 1;
result.err_msg = 'Error opening the web page';

max_count = 5;

% regexp special chars to be escaped
matr_strreplace = {
    '(',    '\(';
    ')',    '\)';
    };
tag_batch0 = tag_batch;
for i=1:size(matr_strreplace,1)
    str1 = matr_strreplace{i,1};
    str2 = matr_strreplace{i,2};
    tag_batch0 = strrep(tag_batch0,str1,str2);
end

ancora = 1;
count = 0;
while ancora
    result = iw('write_cmd',{'run',['iw/san/' imacro],8,struct('URL',url_batch,'TITLE',page_title)});
    result0 = iw('read_fdbk',{''});
    if result.err_code == 0
        result.text = result0.text;
        if isempty(regexp(result0.text,['<h1[^>]*class="title"[^>]*>' tag_batch0 '</h1>'], 'once'))
            fprintf(1,'page not loaded correctly (tag %s not found)\n',tag_batch)
            fprintf(1,'%d: %s\n',result.err_code,result.err_msg)
            fprintf(1,'%d: %s\n',result0.err_code,result0.err_msg)
            disp(result)
            disp(result0)
            %keyboard
        else
            ancora = check_page_text(imacro,result0.text,params);
        end
    else
        % check if macro error was due to a missing image
        z_img = regexp(url_batch,'[0-9_]+.jpg','match');
        if ( ~isempty(z_img) && ~isempty(regexp(result0.text,['\(ERROR_MISSING_OBJECT\) : Parent [0-9]+ path ' z_img{1}], 'once')) )
            img_filename = z_img{1};
            fprintf('*** It was impossible to download image %s, as it is missing from website\n',img_filename)
            
            result.err_code = 2;
            result.err_msg = ['Image ' img_filename ' is missing from website'];
            
            ancora = 0;
        else
            % macro error was due to a real error, retry
            fprintf(1,'%d: %s\n',result.err_code,result.err_msg)
            fprintf(1,'\tretry number %d\n',count)
        end
    end
    count = count+1;
    if (count > max_count)
        ancora = 0;
        result.err_code = 3;
        result.err_msg = ['Repeated failed attempts accessing web page ' url_batch];
    elseif ancora
        pause(1)
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ancora = check_page_text(imacro,text,params)

err_msg = '';

switch imacro
    case 'go_batch'
        % additional check via regexp, to verify the page
        % number of the batch page (when there are many images)
        
        required_page = params{1}; %required batch page es. 2 (number)
        
        z = regexp(text,'Pagina:[\s\n]+(<span>[\s\n]+([0-9]+|<a href="[^"]*">[0-9]+</a>)[\s\n]+</span>[\s\n]+)+','tokens');
        if ~isempty(z)
            % multiple page batch
            txt_pagine = z{1}{1};
            z=regexp(txt_pagine,'([0-9]+|<a href="[^"]*">[0-9]+</a>)','match');
            v_pages = str2double(z');
            detected_page = find(~isnan(v_pages));
        else
            % single page with few images?
            z=regexp(text,'giTitle">[\r\n]+<a href="([^"]+?)">[\r\n]+Immagine\s','tokens'); % search for image links
            if ~isempty(z)
                detected_page = 1;      % single batch page is page 1 by default
            else
                detected_page = NaN;    % probably not on a batch page
            end
        end
        ancora = (detected_page ~= required_page);
        err_msg = sprintf('Batch page error: expected page %d, detected page %d',required_page,detected_page); % shown if (ancora==1)
        
    otherwise
        % default: page is ok
        ancora = 0;
end

if ancora
    disp(err_msg)
end

        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function list_multiple = check_multiple_images(list_stored,list_stored_filename,matr_img_to_dnld_ref)

list_multiple = {};

fprintf(1,'\nChecking for duplicated images:\n')

%% first pass: get file size
list_bytes = ones(size(list_stored))*NaN;
for i_img = 1:length(list_stored)
    % img_id          = list_stored(i_img);
    img_filename    = list_stored_filename{i_img};
    
    z = dir(img_filename);
    list_bytes(i_img,1) = z.bytes;
end
[temp, ind_unique] = unique(list_bytes); % find index to unique occurrence
ind_multiple = setdiff(1:length(list_bytes),ind_unique); % potential clones (same byte-size)

%% leave one element for every byte-size
[temp, ind_unique_bytes] = unique(list_bytes(ind_multiple)); % one element for every byte-size
ind_multiple = ind_multiple(ind_unique_bytes);

%% assemble vectors of potentially multiple images
for i_multiple = 1:length(ind_multiple)
    ind_multiple_i = ind_multiple(i_multiple); % index of i-th potential multiple
    
    bytes_multiple_i = list_bytes(ind_multiple_i);
    vett_multiple_i = find(list_bytes==bytes_multiple_i);  % index of i-th potential multiple
    
    list_stored_i           = list_stored(vett_multiple_i);             % potentially linked image id's
    list_stored_filename_i  = list_stored_filename(vett_multiple_i);    % potentially linked image filenames
    
    list_multiple(i_multiple,:) = {bytes_multiple_i, list_stored_i, list_stored_filename_i}; %#ok<AGROW>
end

%% analize potential multiple images
for i_multiple = 1:size(list_multiple,1)
    % bytes_multiple_i        = list_multiple{i_multiple,1}; % bytes of multiple files
    list_stored_i           = list_multiple{i_multiple,2}; % id's
    list_stored_filename_i  = list_multiple{i_multiple,3}; % filenames
    
    fprintf(1,'\n')
    
    matr_fingerprint = [];
    for i_img = 1:length(list_stored_filename_i)
        img_id          = list_stored_i(i_img);
        img_filename    = list_stored_filename_i{i_img};
        
        img_fingerprint = get_img_fingerprint(img_filename); % horiz vector of numbers characterizing an image
        flg_first_img = check_subbatch_first_id(img_filename,matr_img_to_dnld_ref);
        img_fingerprint = [img_fingerprint flg_first_img]; %#ok<AGROW>
        matr_fingerprint(end+1,:) = img_fingerprint; %#ok<AGROW>
        
        fprintf(1,'\t%3d:\t%dx%d - %d - first in subbatch: %d\n',img_id,img_fingerprint(1),img_fingerprint(2),img_fingerprint(3),img_fingerprint(4))
    end
    
    % if all images are first images of subbatch, it is a false positive
    if all(matr_fingerprint(:,4))
        matr_fingerprint(:,1) = rand(size(matr_fingerprint,1),1);
    else
        matr_fingerprint = matr_fingerprint(:,1:3);
    end        
    
    [temp, ind_unique] = unique(matr_fingerprint,'rows'); % unique images
    ind_multiple = setdiff(1:length(list_stored_i),ind_unique); % potential clones (same byte-size and image-size)
    % detect all images equal to the detected clones
    ind_rows = [];
    for i_ind_i = 1:length(ind_multiple)
        ind_tmp = ind_multiple(i_ind_i);
        
        ind_rows = [ind_rows; find(all((matr_fingerprint==repmat(matr_fingerprint(ind_tmp,:),size(matr_fingerprint,1),1))'))']; %#ok<AGROW>
    end
    ind_multiple = unique(ind_rows); % group of clones with the same file size
    
    % update the group of clones
    list_stored_i           = list_stored_i(ind_multiple);
    list_stored_filename_i  = list_stored_filename_i(ind_multiple);
    
    if isempty(list_stored_i)
        fprintf(1,'\tFalse positive.\n')
    end
    
    % update the list of groups of clones
    list_multiple{i_multiple,2} = list_stored_i; %#ok<AGROW> % update id's
    list_multiple{i_multiple,3} = list_stored_filename_i; %#ok<AGROW> % update filenames
end
if ( ~isempty(list_multiple) )
    % remove potential groups that have become empty (false positive)
    list_multiple = list_multiple(~cellfun('isempty',list_multiple(:,2)),:);
end


%% remove multiple images
if ( ~isempty(list_multiple) )
    for i_multiple = 1:size(list_multiple,1)
        bytes_multiple_i        = list_multiple{i_multiple,1}; % bytes of multiple files
        list_stored_i           = list_multiple{i_multiple,2}; % id's
        list_stored_filename_i  = list_multiple{i_multiple,3}; % filenames
        
        ks = sprintf('%d,',list_stored_i);
        ks=ks(1:end-1);
        num_clones = length(list_stored_i);
        fprintf(1,'\n\tMultiple files (%d) detected and to be deleted (same size: %d bytes): image id''s: %s\n',num_clones,bytes_multiple_i,ks);
        
        cmd = ['delete ' sprintf('''%s'' ',list_stored_filename_i{:})];
        eval(cmd);
        
        fprintf(1,'\tDone (%d files removed).\n',num_clones);
    end
else
    fprintf(1,'\n\tNo multiple images detected\n')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flg_first_img = check_subbatch_first_id(img_filename,matr_img_to_dnld_ref)
% Return the subbatch id in case of first image of the subbatch. If the
% image is not the first, then inverse the sign.
% If two images are identical, they could be the first images of each
% subbatch: in this case, it is acceptable to have 2 identical images

z = regexp(img_filename,'\/([0-9]+)_([0-9]+)\.','tokens');
% ks_subbatch = z{1}{1};
ks_id       = z{1}{2};

ind_img = find(cell2mat(matr_img_to_dnld_ref(:,1))==str2double(ks_id));
img_url = matr_img_to_dnld_ref{ind_img,2};
z = regexp(img_url,'\/([0-9]+)_([0-9]+)\.','tokens');
ks_id_url = z{1}{2};
img_id_url = str2double(ks_id_url);
flg_first_img = (img_id_url==1);
% subbatch_id = str2double(ks_subbatch);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function img_fingerprint = get_img_fingerprint(img_filename)

img_bitmap = imread(img_filename);  % image greyscale bitmap
img_size = fliplr(size(img_bitmap)); % width x height
img_fingerprint = [img_size(1) img_size(2) sum(img_bitmap(:))];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [matr_id list_stored list_stored_filename list_dummy_filename] = detect_images_to_download(folder_film,matr_id_ref)
% some batches have missing images (stored in list_dummy_filename), such as:
%     Caposele_Nati_1827_988/	images 3 and 5
%     Caposele_Nati_1829_990/   images 3 and 5
%     Caposele_Nati_1851_1006/	images 2 and 4
%     ...

list_id_ref = cell2mat(matr_id_ref(:,1));
if ~exist(folder_film,'dir')
    mkdir(folder_film)
    matr_id = matr_id_ref;
    list_stored = [];
    list_stored_filename = {};
    list_dummy_filename = {};
else
    % dummy files to mark missing images
    z = dir([folder_film '*.jpg.missing.txt']);
    [list_dummy_filename{1:length(z)}] = deal(z.name);
    list_dummy_filename = list_dummy_filename';
    z = regexp(list_dummy_filename,'_([0-9]+)','tokens');z2=[z{:}]';
    if ~isempty(z)
        list_dummy = str2double([z2{:}]'); % it's already checked
    else
        list_dummy = []; % no verified missing image
    end
    if any(isnan(list_dummy))
        fprintf(1,'**** There are unexpected missing images!!!\n');
        disp(list_dummy_filename)
        pause
    end
    
    % downloaded images
    z = dir([folder_film '*.jpg']);
    [list_stored_filename{1:length(z)}] = deal(z.name);
    list_stored_filename = list_stored_filename';
    z = regexp(list_stored_filename,'_([0-9]+)','tokens');z2=[z{:}]';
    if ~isempty(z)
        list_stored = str2double([z2{:}]'); % it's already downloaded
    else
        list_stored = []; % nothing already downloaded
    end
    
    % calculate list of id to be downloaded
    [list_id_ref_real ind] = setdiff(list_id_ref,list_dummy); % remove dummy images (not available)
    matr_id_ref_real = matr_id_ref(ind,:);
    [list_id ind] = setdiff(list_id_ref_real,list_stored); % remove already downloaded images
    matr_id = matr_id_ref_real(ind,:);
    
    list_unexpected_id = setdiff(list_stored,list_id_ref_real); % images that are downloaded, but exceed the number of images in the batch!
    if ~isempty(list_unexpected_id)
        fprintf(1,'**** There are unexpected images!!!\n');
        disp(list_unexpected_id)
        pause
    end
    
    list_stored_filename = cellfun(@(x) [folder_film x],list_stored_filename,'UniformOutput',false); % filename to fullpath
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flg_ok = download_img(ind_img,url_img,dnld_file,batch_folder,num_figures)

flg_ok = 0;

bytes_thr = 5e5; % [bytes] min size to accept image as ok

z = regexp(url_img,'[0-9_]*\.jpg','match');
name_img = z{1}; % es. 005680090_00003.jpg
img_file = [batch_folder name_img]; % es. /home/ceres/iMacros/Downloads/Caposele_Nati_1827_988/005680090_00003.jpg
% ensure that the img id is present in the image filename. This is
% necessary for multisubbatch batches, where the same image id is repeated
% (subbatches always start from 1)
img_file = regexprep(img_file,'_[0-9]+\.',['_' sprintf(['%0' num2str(num_figures) 'd'],ind_img) '\.']);

result0 = open_batch_page('go_image',url_img,['Immagine<SP>' num2str(ind_img)],['Immagine ' num2str(ind_img)],{});
if ( result0.err_code == 0 )
    % image was downloaded correctly
    result0 = iw('write_cmd',{'run','iw/san/zoom_image',8,struct()});
    if (result0.err_code ~= 0)
        fprintf(1,'%d: %s\n',result0.err_code,result0.err_msg)
    end
    
    try_movefile = wait_for_downloaded_file(dnld_file,bytes_thr);
    if try_movefile
        movefile(dnld_file,img_file);
        
        z = dir(img_file);
        flg_ok = (z(1).bytes > bytes_thr);
    end
elseif ( result0.err_code == 2 )
    % image is missing from website (not a real download error)
    
    % create dummy file to mark the fact that image is not available
    dummyfile = [img_file '.missing.txt'];
    fid = fopen(dummyfile,'w+');
    fclose(fid);
    
    flg_ok = 1;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function try_movefile = wait_for_downloaded_file(dnld_file,bytes_thr)

try_movefile = 0;

max_count = 10;

z = dir(dnld_file);
count = 0;
while ( (isempty(z) || (z(1).bytes < bytes_thr)) && (count < max_count) )
    % file download not completed
    pause(1)
    z = dir(dnld_file);
    count = count+1;
end
if (count>=max_count)
    % repeat zoom macro
    result0 = iw('write_cmd',{'run','iw/san/zoom_image',8,struct()});
    if (result0.err_code ~= 0)
        fprintf(1,'%d: %s\n',result0.err_code,result0.err_msg)
    end
    pause(20)
    z = dir(dnld_file);
    if ( isempty(z) || (z(1).bytes < bytes_thr) )
        % still missing!
    else
        try_movefile = 1;
    end
else
    % finished before max tries, ok
    try_movefile = 1;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str = extract_params(params,list_fields)

if length(params)~=length(list_fields)
    disp(params)
    disp(list_fields)
    error('Wrong number of params (%d)!',length(params))
end

str = struct();
for i_field=1:length(list_fields)
    field = list_fields{i_field};
    val = params{i_field};
    str.(field) = val;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks = prepare_folder(tag)

ks = regexprep(tag,'[^a-zA-Z0-9\-]+','\+');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function folder = prepare_tag(tag)

% remove text in parenthesis
tag = regexprep(tag,'\([^\)]*\)','');

% remove text in parenthesis
separators = '\s\,\+\(\)';
if regexp(tag,['[' separators ']'])
    z = regexp(tag,['[^' separators ']+'],'match');
    word1 = z{1};
    word2 = z{2};
    word1_ = [upper(word1(1)) word1(2:end)];
    word2_ = [upper(word2(1)) word2(2:end)];
    folder = [word1_ word2_];
else
    folder = tag;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [webfolder_info matr_items] = load_webfolder_info(info_fullname,tag_webfolder)

matr_items = {};
webfolder_info = struct();

field = prepare_tag(tag_webfolder);


% try to load detected info
if exist(info_fullname,'file')
    z = load(info_fullname);
    if isfield(z,'webfolder_info')
        webfolder_info = z.webfolder_info;
        if isfield(webfolder_info,field)
            matr_items  = webfolder_info.(field);
        end
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function save_webfolder_info(info_fullname,tag_webfolder,matr_items)

webfolder_info = load_webfolder_info(info_fullname,tag_webfolder);

field = prepare_tag(tag_webfolder);

% save detected info
webfolder_info.(field) = matr_items;
save(info_fullname,'webfolder_info')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function create_folder_if_needed(folder)

if ( ~exist(folder,'dir') )
    mkdir(folder)
end
