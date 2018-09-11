function [flg_editable, str_status, str_hours, matr_comm] = ROC
% [flg_editable, str_status, str_hours, matr_comm] = ROC;
%
% enter ROC hours
%

flg_editable    = 0;
str_status      = struct();
str_hours       = struct();
matr_comm       = {};

username = 'ceres'
password = 'tdC1e!um'
%matr_comm = {'KIEC002_PERT_PWT',0.50;'KIGI004_PERT_PWT',0.30;'KIGI006_PERT_PWT',0.20} % tutto il 2017
matr_comm = {'KIEC002_PERT_PWT',1} % da gen 2017 a ...
vec_target = datevec(now-7); % default date: point to 7 days ago (previous week)
flg_force_loading = 1

close all

result = iw('grab_session');
if (result.err_code == 0)
    sid = result.sid
    
    % register clean up object to release the session in case of CTRL-C
    CleanupObj = onCleanup(@() iw('release_session',{sid}));
else
    error('Problems connecting to iMacros wrapper')
end

%% determine target day
vec_target = ask_user_ks_date(vec_target); % let user change target date

%% login
result = iw('config_iw',{'debug',0}); %#ok<NASGU>

result = iw('write_cmd',{sid,'run','iw/roc/roc_login',10,struct('USERNAME',username,'PASSWORD',password)});
if (result.err_code == 11)
    error('iMacrosWrapper is not running properly, please check.')
end
show_error(result);
if ~isempty(regexp(result.err_msg,'element INPUT specified by ID:sap-user was not found','once'))
    disp('Login was already done')
end

try
    %% open calendar week
    [ks_month_tag ks_month_pos ks_day] = determine_cw_pos(vec_target);
    clear result
    result = iw('write_cmd',{sid,'run','iw/roc/roc_select_cw',10,struct('MONTH_TAG',ks_month_tag,'MONTH_POS',ks_month_pos,'DAY',ks_day)});
    show_error(result)
    
    %% determine hours to be managed
    [str_hours, str_status] = analyse_OreROC(sid);
    disp(str_status.msg)
    h_cons = str_hours.h_cons;
    h_pres = str_hours.h_pres;
    if ( (str_status.status == 'g') && ~flg_force_loading )
        fprintf(1,'Ore già consuntivate (%.2f).\n',h_cons)
    else
        % there's something to do:
        
        %% manage cw (calendar week) status, reopening it if needed
        flg_editable = reopen_cw_status(sid,flg_force_loading);
        if flg_editable
            %% calculate ROC hours to be entered
            [str_ROC matr_comm] =  calculate_ROC_hours(matr_comm,h_pres);
            clear result
            result = iw('write_cmd',{sid,'run','iw/roc/roc_enter_hours',25,str_ROC});
            show_error(result)
            
            %% check that hours were entrered correctly
            [str_hours, str_status] = analyse_OreROC(sid);
            disp(str_status.msg)
        end
    end
catch me %#ok<NASGU>
    if ( exist('result','var') && (result.err_code ~= 0) )
        % error inside iw call
        show_error(result)
    else
        disp(lasterr) %#ok<LERR>
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [str_hours str_status] = analyse_OreROC(sid)
% analyse html code from OreROC.txt, saved externally

str_hours   = [];
str_status  = [];

% read page
result = iw('read_fdbk',{sid,'OreROC.txt'});

%% detect ROC hours to be managed
z = regexp(result.text,'ALTERNATING'',[0-9]+:''[^'']+','match')';
if isempty(z)
    % error in page code, return
    str_status.msg = 'ERROR: web page format not correct!';
    return
end

z2 = strrep(z,'\x20','');
z3 = regexprep(z2,'ALTERNATING'',[0-9]+:''','');
h_cons = str2double(strrep(z3{5},',','.'));
h_pres = str2double(strrep(z3{6},',','.'));

str_hours = struct();
str_hours.h_cons = h_cons;
str_hours.h_pres = h_pres;

%% detect cw status (green, yellow or red?)
z = regexp(result.text,'s_s_tl_.','match');
ch_status = z{end}(end);
switch ch_status
    case 'g'
        msg_status = sprintf('Ok, ore caricate (%.2f)',h_cons);
    case 'y'
        if (h_pres==0)
            msg_status = sprintf('Ok, non ci sono ore da caricare (%.2f)',h_pres);
        else
            msg_status = sprintf('ATTENZIONE! Le ore sono state caricate (%.2f), ma bisogna salvare',h_pres);
        end
    case 'r'
        msg_status = sprintf('ATTENZIONE! Ci sono ore da caricare (%.2f,%.2f)',h_cons,h_pres);
    otherwise
        error('Unknown status: %s',ch_status);
end

%% cross check status with hours
if (h_cons==h_pres)
    % no ROC hours to be loaded
    if (ch_status == 'r')
        fprintf(1,'WARNING!!! Lo status è rosso, ma non ci sono ore da caricare (%.2f,%.2f)!\n',h_cons,h_pres)
    end
else
    % h_cons~=h_pres: ROC hours need to be loaded
    if (ch_status == 'g')
        fprintf(1,'WARNING!!! Lo status è verde, ma ci sono ore da caricare (%.2f,%.2f)!\n',h_cons,h_pres)
    end
end

%% prepare output
str_status = struct();
str_status.status  = ch_status;
str_status.msg     = msg_status;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function vec = ask_user_ks_date(vec)

vec = datevec(datenum(vec));
year = vec(1);
month = vec(2);
day = vec(3);

callback_fcn = 'h=findobj(''Tag'',''edit_control'');h=h(end);ks_date=get(h,''String'');uiresume(gcf);close(gcf)';

ks_date = sprintf('%02d.%02d.%04d',day,month,year);
fig=figure;
pos=get(fig,'Position');
pos(3:4)=[200 140];
set(fig,'Position',pos);
uicontrol('Parent', fig, 'Style', 'edit','String','Target date:','Position',[20 100 80 20]);
uicontrol('Parent', fig, 'Style', 'pushbutton','String','Ok','Position',[20 20 80 20],'CallBack',callback_fcn);
h_edit = uicontrol('Parent', fig, 'Tag','edit_control', 'Style', 'edit','String',ks_date,'Position',[20 60 80 20],'CallBack',callback_fcn);
uicontrol(h_edit);
uiwait(gcf)
ks_date=evalin('base','ks_date;'); % retrieve string value from base workspace (callbacks work in that context)
fprintf(1,'Target week contains day %s.\n',ks_date);
vec2=sscanf(ks_date,'%d.%d.%d');
vec(2:3)=vec2([2 1]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [ks_month_tag ks_month_pos ks_day] = determine_cw_pos(vec)
% determine target day coordinates in calendar week window

day   = vec(3);
month = vec(2);
%year = vec(1);

list_month = {'Gennaio','Febbraio','Marzo','Aprile','Maggio','Giugno','Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre'};
vec(3) = 0; % point to last day of previous month
vec = datevec(datestr(datenum(vec)));
max_day_of_month = vec(3); % number of days in previous month
num_duplicated_days = weekday(datenum(vec))-1; % number of days present in current month calendar, but belonging to previous month
if ( day>=max_day_of_month-(num_duplicated_days-1) )
    % the target day is the second occurrence of the day in calendar for target month (first
    % one is from previous month)
    month_pos_ = 2;
else
    % the target day is the only occurrence in calendar for target month
    month_pos_ = 1;
end
vec_now = datevec(now);
month_pos=month-(vec_now(2)-1)+1; % calendar position inside the window. The first calendar is for previous month, second for current one, third for next one, etc.
ks_month_tag = list_month(vec_now(2)+month_pos-2);
ks_month_pos = num2str(month_pos_);
ks_day = num2str(day);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [str_ROC matr_comm] =  calculate_ROC_hours(matr_comm,h_pres)
% calculate ROC hours to be entered

step=0.25; % ROC hours rounding step

disp('Carica ore...')
% sort ratios
[~, ind] = sort(-cell2mat(matr_comm(:,2)));
matr_comm = matr_comm(ind,:);
% calculate ROC hours using ratios
v1 = h_pres*cell2mat(matr_comm(:,2));
v2=round(v1/step)*step;
if sum(v2)>h_pres
    % rounding let to overcome the total hours
    v2(1)=v2(1)-step;
elseif sum(v2)<h_pres
    % rounding let not to reach the total hours
    v2(1)=v2(1)+step;
end
disp(v2)
fprintf(1,'h_pres = %.2f --> sum = %.2f\n',h_pres,sum(v2))
matr_comm(:,3) = num2cell(v2);

%% enter ROC hours
str_ROC = struct();
for i_comm = 1:size(matr_comm,1)
    hour_i = strrep(num2str(matr_comm{i_comm,3},'%.2f'),'.',',');
    str_ROC.(['COMMESSA' num2str(i_comm)]) = matr_comm{i_comm,1};
    str_ROC.(['HOURS' num2str(i_comm)]) = hour_i;
end
disp(str_ROC)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function flg_editable = reopen_cw_status(sid,flg_force_loading)
% manage cw (calendar week) status, reopening it if required

flg_editable = 0;
if flg_force_loading
    disp('Provo a riaprire la settimana...')
    result = iw('write_cmd',{sid,'run','iw/roc/roc_update_cw',10,struct()});
    show_error(result)
    [~, str_status] = analyse_OreROC(sid);
    if (str_status.status == 'g')
        disp('*** La settimana non può essere modificata!')
    else
        disp('    Fatto.')
        flg_editable = 1;
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function show_error(result)

if (result.err_code ~= 0)
    fprintf(1,'%d: %s\n',result.err_code,result.err_msg)
end
