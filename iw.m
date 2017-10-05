function result = iw(action,varargin)
%
% result = iw(action,varargin)
%
% First of all, run the imacros_wrapper.js macro in your browser!
%
% input:
%   action :
%       'write_cmd': require a command to imacros_wrapper.js.
%                    No additional output fields.
%                    It must be followed by a cell array in the form
%                    {iw_action[,additional params]} where
%           iw_action:
%               'stop': no additional param needed. Require
%                       imacros_wrapper_js looping stop.
%               'run' : param_struct param needed. Require iMacros macro
%                       execution. macro params are defined in the
%                       param_struct, with the form struct(timeout_fdbk,param1_name,param1_value,...)
%                       where:
%                   timeout_fdbk: [s] max time waiting for macro feedback
%                                 before triggering timeout
%               'set_param': set a param for imacros_wrapper
%                    iw_action must be followed by a cell array in the form
%                    {iw_par1_name,iw_par1_val[,iw_parX_name,iw_parX_val,...]} where
%                   iw_parX_val is a string, and iw_par1_name:
%                       'dump_type': see iMacros SAVEAS help for more details
%                           'CPL': complete web page, with images as well
%                           'TXT' : only extract text
%                           'HTM': extract HTML
%                           'BMP','PNG','JPEG': bitmap screenshot of the
%                           web page
%                       'pause_time': string with pause in s between subsequent cmd
%                                     read in imacros_wrapper.js idle loop
%                       'flg_clear': {'0','1'} '1' --> issue iMacros CLEAR
%                                    command at each loop. Improves
%                                    performances, but prevents login and
%                                    session management
%       'read_fdbk': read web page dump.
%                    It must be followed by a cell array in the form
%                    {filename} where
%                       filename: name of the dump filename. Empty for default dump
%                                 file (output.csv')
%                    Additional output fields:
%                    'dump': txt or html code from dumped web page.
%                    Action input must be followed by no other params
%       'log': show lod msg
%              cell array Params are in the form: {msg,debug}, where
%           msg: log message
%           debug: [0,1] 1 --> show msg; 0 --> suppress output
%       'pause_rnd': pseudo random pause
%              cell array Params are in the form: {avg,cov}, where
%           avg_time: [s] average pause time
%           st_dev: [s] standard deviation of pause time
%       'rnd_item': select a random item from a cell array list
%                   Additional output fields:
%                   'item': random item extracted from list
%                   cell array Params are in the form: {list}, where
%                       list: cell array list of items
%       'ask_for_human': stop execution and wait for interaction. Close the
%                        colored window to return execution to script.
%                        Additional output fields:
%                           'flg_return': user returned control to script
%                        Action input must be followed by a cell array in the form
%                           {timeout} where
%           timeout: [s] timeout after which control is given back
%       'iMacros_rootfolder': return iMacros root folder
%                             Additional output fields:
%                               'folder': root folder for iMacros
%       'config_iw': configure iw behaviour (Matlab side)
%                    Action input must be followed by a cell array in the form
%                       {param,value} where
%           param: name of configurable parameter {'debug'}, with
%                  corresponding values 0 (normal behaviour) or 1 (debug
%                  messages)
%           value: value to be set for parameter param
%
% output:
%   result: struct with following fields:
%       err_code: error code. See possible codes below
%       err_msg : error message
%       [additional fields]: depending on required action, see action help above
%
% % es.:
% result = iw('config_iw',{'debug',1})
% result = iw('write_cmd',{'run','iw/iw_test/Google',6,struct('SEARCHSTRING','Genealogia di Caposele')})
% result = iw('write_cmd',{'set_param',struct('dump_type','HTM')}) % 'TXT','CPL','TXT','HTM','BMP','PNG','JPEG'
% result = iw('write_cmd',{'set_param',struct('pause_time','0.5')})
% result = iw('write_cmd',{'set_param',struct('flg_clear','1')})
% result = iw('read_fdbk',{''})
% result = iw('iMacros_rootfolder',{});folder = result.folder
% result = iw('write_cmd',{'set_param',struct('pause_time','0.2')})
% result = iw('log',{'this is a debug msg',1})
% result = iw('pause_rnd',{4,1})    % random pause (avg = 4 s, std dev = 1 s)
% result = iw('rnd_item',{{'ciao','hello','salve'}})
% result = iw('ask_for_human',{4})  % wait for human interaction for 4 s
% result = iw('write_cmd',{'stop'}) % stop iMacros wrapper infinite loop
%
% % build a search string ranking
% result = iw('write_cmd',{'set_param',struct('pause_time','0.5','dump_type','TXT')})
% list = {'Fiat','Chrysler','FCA','Volkswagen','Toyota'}';
% for i=1:size(list,1);
%   result = iw('write_cmd',{'run','iw/iw_test/Google',6,struct('SEARCHSTRING',list{i,1})})
%   result = iw('read_fdbk',{''})
%   z=regexp(result.text,'Circa ([0-9\.]+) risultati','tokens');if isempty(z),num_pages=NaN;else,num_pages=str2double(strrep(z{1}{1},'.',''));end,list{i,2}=num_pages;
% end
% result = iw('write_cmd',{'stop'})
% [temp ind] = sort(-cell2mat(list(:,2)));list=list(ind,:);format long;disp('Classifica delle stringhe di ricerca:');disp(list);format short
% bar(cell2mat(list(:,2)));mx=max(cell2mat(list(:,2)));grid on;ylabel('Google hits');title(['Logo ranking - ' datestr(now,'mmm dd, yyyy')]);for i=1:size(list,1),val=list{i,2};tag=list{i,1};text(i-length(tag)/25,val+mx/30,tag);end;
% tag_list = ['list' datestr(now,'yyyy_mm_dd')];filename_arc='logo_arc.mat';if exist(filename_arc,'file'),z=load(filename_arc);else z=struct();end;z.(tag_list)=list;save(filename_arc,'-struct','z');
% list=fieldnames(z);z_=regexp(list,'[0-9]+_[0-9]+_[0-9]+','match');z2=[z_{:}]';v_day=datenum(z2,'yyyy_mm_dd');bulk=[];figure(99),hold on,grid on,title('Number of Google results in time');for i_day = 1:length(list),tag=list{i_day};str=z.(tag);[tmp ind]=sort(str(:,1));str=str(ind,:);leg=str(:,1);bulk=[bulk cell2mat(str(:,2))];end;num_days=length(list);color='bgrkmc';for i_logo=1:size(bulk,1),plot(v_day,bulk(i_logo,:),['.-' color(i_logo)]),end,legend(leg,'Location','best'),   set(gca,'XTickLabel',''),p=get(gca,'position');p(2)=p(2)+.1; p(4)=p(4)-.1;set(gca,'position',p);text(v_day,zeros(1,length(list))-0,z2,'rotation',90,'horizontal','right','interpreter','none'),legend(leg,'Location','Best')
%
% % automatize image download from a website
% result = san('dnld_typology',{'http://www.antenati.san.beniculturali.it/v/Archivio+di+Stato+di+Salerno/Stato+civile+della+restaurazione/Caposeleprovincia+di+Avellino/Matrimoni/','Caposele_Matrimoni','Matrimoni'})
%
%
%
% error codes for write_cmd action:
% 0; % action executed correctly
% 1; % end loop request
% 2; % unknown action requested
% 3; % error reading command
% 4; % error dumping web page
% 10; % Unable to write cmd file <fullname_cmd>
% 11; % Timeout waiting for feedback
% 12; % No feedback available from iMacros wrapper
% from run:
% 	-2; % macro error (iMacros error code is in err_msg)
% from set_param:
%   -3; % unknown internal param
%
% error codes for read_fdbk action:
% 1; % error reading dump file
%
% error codes for config_iw action:
% 1; % wrong parameter name
% 2; % wrong parameter value
%

if ismember(action,{'write_cmd','read_fdbk','log','pause_rnd','rnd_item','reset_fdbk','ask_for_human','iMacros_rootfolder','config_iw'})
    result = perform_action(action,varargin);
else
    error('Unknown action %s!',action)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = perform_action(action,varargin)

err_code = 0;
err_msg = '';
result = struct();

switch action
    case 'write_cmd'
        iMacros_name = varargin{1}{1}{1};
        params       = varargin{1}{1}(2:end);
        result0 = write_cmd(iMacros_name,params);
        result = result0; % overwrite err_code, also for negative values
        err_code = result0.err_code;
        err_msg  = result0.err_msg;
    case 'read_fdbk'
        filename = varargin{1}{1}{1};
        result0 = read_fdbk(filename);
        result.text = result0.text;
        result.filename_read = result0.filename_read;
    otherwise
        % service actions (those that don't interact directly with iMacros)
        params = varargin;
        [result result0] = service_actions(action,params,result);
end

if (result0.err_code>0)
    % some error was detected
    err_code = result0.err_code;
    err_msg  = result0.err_msg;
end

result.err_code = err_code;
result.err_msg = err_msg;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [result result0] = service_actions(action,params,result)

switch action
    case 'log'
        msg   = params{1}{1}{1};
        debug = params{1}{1}{2};
        log(msg,debug);
        result0.err_code = 0; % default result as there is no output
    case 'pause_rnd'
        avg_time    = params{1}{1}{1};
        st_dev      = params{1}{1}{2};
        result0 = pause_rnd(avg_time,st_dev);
        result.t_pause = result0.t_pause;
    case 'rnd_item'
        list = params{1}{1}{1};
        item = rnd_item(list);
        result.item = item;
        result0.err_code = 0; % default result as there is no output
    case 'ask_for_human'
        timeout = params{1}{1}{1};
        result0 = ask_for_human(timeout);
        result.flg_return = result0.flg_return;
        result0.err_code = 0; % default result as there is no output
    case 'iMacros_rootfolder'
        folder = iMacros_rootfolder();
        result.folder = folder;
        result0.err_code = 0; % default result as there is no output
    case 'config_iw'
        param_name   = params{1}{1}{1};
        param_value  = params{1}{1}{2};
        result0 = config_iw(param_name,param_value);
    otherwise
        error('I shouldn''t be here! (action %s)',action)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = config_iw(param_name,param_value)
% err_code:
% 1; % wrong parameter name
% 2; % wrong parameter value
global str_iw
str_iw = init_str_iw(str_iw);

err_code = 0;
err_msg  = '';
result = struct();

switch param_name
    case 'debug'
        % 0: normal behaviour
        % 1: show debug messages
        if ismember(param_value,[0,1])
            str_iw.debug = param_value;
        else
            err_code = 2;
            err_msg  = 'Wrong parameter value';
        end
    otherwise
        err_code = 1;
        err_msg  = 'Wrong parameter name';
end

result.err_code = err_code;
result.err_msg  = err_msg;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function item = rnd_item(list)

n = length(list);
ind = ceil(rand*n);
item = list{ind};



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function log(msg,debug)

if debug
    fprintf(1,'%s\n',msg)
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = pause_rnd(avg_time,st_dev)

err_code = 0;
err_msg = 0;
result = struct();

t_pause = avg_time + st_dev.*randn;
pause(t_pause)

result.err_code = err_code;
result.err_msg = err_msg;
result.t_pause = t_pause;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = read_fdbk(filename)

err_code = 0;
err_msg = 0;

if isempty(filename)
    % default iw dump file
    filename = 'output.htm';
end

filename_read = [iMacros_rootfolder() 'Downloads' filesep filename];

z = dir(filename_read);

if ~isempty(z)
    fid = fopen(filename_read, 'r');
    text = char(fread(fid, z.bytes, 'char')');
    fclose(fid);
else
    text = '';
    err_code = 1;
    err_msg = ['Error reading dump file ' filename_read];
end

result.err_code = err_code;
result.err_msg = err_msg;
result.text = text;
result.filename_read = filename_read;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function reset_fdbk()

[temp, filename_read] = read_fdbk(); %#ok<ASGLU>

delete(filename_read);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = write_cmd(action,params)
% error codes for write_cmd action:
% 0; % command executed correctly
% 1; % end loop request
% 2; % unknown action requested
% 3; % error reading command
% 4; % error dumping web page
% 10; % Unable to write cmd file <fullname_cmd>
% 11; % Timeout waiting for feedback
% from run:
% 	-2; % macro error (iMacros error code is in err_msg)
% from set_param:
%   -3; % unknown internal param

global str_iw
str_iw = init_str_iw(str_iw);

err_code = 0;
err_msg = 0;
result = struct();

fullname_retcode = [iMacros_rootfolder() 'Downloads' filesep 'return_code.txt']; % output file for return code and msg
fullname_cmd = [iMacros_rootfolder() 'Downloads' filesep 'command.csv'];
header_line = 'ACTION,PARAMS';
timeout_fdbk = 6; % [s]

str_separ.and = '|&';
str_separ.eq  = '|=';

%% parse action
switch action
    case 'run'
        script       = params{1};
        timeout_fdbk = params{2}; % this overrides the default value
        param_struct = params{3};
        
        ks_params = struct_to_string(param_struct,str_separ);
        ks_param_line = [script str_separ.and ks_params];
        cmd_line = [action ',"' ks_param_line '"'];
        
    case 'stop'
        cmd_line = 'stop,';
        
    case 'set_param'
        param_struct = params{1};
        ks_params = struct_to_string(param_struct,str_separ);
        cmd_line = [action ',"' ks_params '"'];
        
    otherwise
        err_code = 2;
        err_msg  = ['Unknown action requested: ' action];
        %error('Unknown action %s',action)
end

if (err_code == 0)
    %% proceed requiring iw action
    if str_iw.debug
        disp(cmd_line)
    end
    text = sprintf('%s\n%s',header_line,cmd_line);
    
    % execute and get feedback
    [err_code err_msg] = write_and_wait_fdbk(text,fullname_cmd,fullname_retcode,timeout_fdbk);
    
    if (err_code == -1)
        % override strange run error management in case of success (no error --> 0)
        err_code = 0;
    end
end

result.err_code = err_code;
result.err_msg = err_msg;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function str_iw = init_str_iw(str_iw)

matr_default = {
    'debug',    0;
    };

if isempty(str_iw)
    str_iw = struct();
end

for i_field = 1:size(matr_default,1)
    field = matr_default{i_field,1};
    value = matr_default{i_field,2};
    if ~isfield(str_iw,field)
        str_iw.(field) = value;
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ks_params = struct_to_string(param_struct,str_separ)

list = fieldnames(param_struct);
ks_params = '';
for i_field=1:length(list)
    field = list{i_field};
    ks_params = [ks_params field str_separ.eq param_struct.(field) str_separ.and]; %#ok<AGROW>
end
ks_params = ks_params(1:end-2);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [err_code err_msg] = write_and_wait_fdbk(text,fullname_cmd,fullname_retcode,timeout_fdbk)

% get timestamp
z_old = dir(fullname_retcode);

fid = fopen(fullname_cmd,'wt');
if (fid>0)
    fwrite(fid,text,'char');
    fclose(fid);
    
    %% wait for macro execution and read return code
    % wait for retcode
    ancora = 1;
    tstart = cputime;
    while ancora
        z_new = dir(fullname_retcode);
        z_cmd = dir(fullname_cmd);
        pause(0.5);
        flg_no_timeout = cputime-tstart < timeout_fdbk;
        flg_no_feedback = isequal(z_old,z_new) || isempty(z_new);
        flg_iw_no_restart = ~isempty(z_cmd); % is iMacros wrapper is stopped and restarted, command file is deleted. In this case, better to issue a timeout error
        ancora = (flg_no_feedback && flg_no_timeout && flg_iw_no_restart);
    end
    
    if (~flg_no_feedback)
        % parse retcode file and extract err_code and err_msg
        fileID = fopen(fullname_retcode,'r','n');
        fseek(fileID,-1000,'eof'); % try positioning 1000 chars before end of file, as we're interested in last line. If it fails, no problem: the file is small
        txt = char(fread(fileID,z_new.bytes)');
        fclose(fileID);
        if ( (~isempty(txt)) && (double(txt(1))==239) )
            % skip first 3 encoding chars
            txt = txt(4:end);
        end
        [err_code err_msg] = get_fdbk_from_text(txt); % extract feedback
    else
        % timeout
        err_code = 11;
        err_msg  = 'Timeout waiting for feedback';
    end
else
    % error writing cmd
    err_code = 10;
    err_msg  = ['Unable to write cmd file ' fullname_cmd];
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [err_code err_msg] = get_fdbk_from_text(txt)

z = strtrim(regexp(txt,'[\r\n][^\r\n]+[\r\n]*$','match')); % read last line
if isempty(z)
    % try single line
    z = strtrim(regexp(txt,'[^\r\n]+[\r\n]*$','match'));
end
if ~isempty(z)
    lastline = strtrim(z{1});
    fields = regexp(lastline,'","','split');
    fields{1} = fields{1}(2:end);
    fields{end} = fields{end}(1:end-1);
    
    err_code = str2double(fields{2});
    err_msg  = fields{end};
else
    err_code = 12;
    err_msg  = 'No feedback available from iMacros wrapper';
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function result = ask_for_human(timeout)

err_code = 0;
err_msg = 0;
%flg_return = 0;
result = struct();

figure(999);
set(gcf,'ToolBar','none','MenuBar','none','NumberTitle','off','Name',sprintf('User interaction within %.0f s',timeout))
h2=fill([0 1 1 0],[1 1 0 0],[1 0 0]);

c = [1 0 0;0 1 0; 0 0 1];
ancora = 1;
count = 0;
color = 3;
while ancora
    color = rem(color+1,size(c,1))+1;
    count = count+1;
    try
        delete(h2)
        h2=fill([0 1 1 0],[1 1 0 0],c(mod(count-1,size(c,1))+1,:));
        text(0.1,0.5,'Close the figure to resume','FontSize',24);
        set(gca,'Visible','off')
        flg_return = 0;
        ancora = (count<=timeout);
    catch %#ok<CTCH>
        % figure was closed
        flg_return = 1;
        ancora = 0;
    end
    if (ancora)
        pause(1);
    else
        if (flg_return==0)
            % figure was not closed, close it here
            close(999)
        end
    end
end

result.err_code = err_code;
result.err_msg = err_msg;
result.flg_return = flg_return;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function rootfolder = iMacros_rootfolder()

if isunix
    home = getenv('HOME');
    rootfolder = [home '/iMacros/'];
else
    % home = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
    home = getenv('USERPROFILE');
    rootfolder = [home '\Documents\iMacros\'];
end
