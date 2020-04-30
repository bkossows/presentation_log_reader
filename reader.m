%% Generic log analyzer
%% B. Kossowski

%% Run in batch mode
%files=spm_select; for i=1:size(files,1); filename=files(i,:); reader; end;

%% Initialize variables.
filename='/Users/bkossows/Lokalne/kasia-logi/dys047-ventral_loc_run2.log';
[folder,name,ext]=fileparts(filename);
delimiter = '\t';
startRow = 4;

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%q%q%q%q%q%q%q%q%q%q%q%q%q%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[1,2,5,6,7,8,9,10,13]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(numbers, thousandsRegExp, 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end


%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [1,2,5,6,7,8,9,10,13]);
rawCellColumns = raw(:, [3,4,11,12]);


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Allocate imported array to column variable names
global Time Code Duration
Subject = cell2mat(rawNumericColumns(:, 1));
Trial = cell2mat(rawNumericColumns(:, 2));
EventType = rawCellColumns(:, 1);
Code = rawCellColumns(:, 2);
Time = cell2mat(rawNumericColumns(:, 3));
TTime = cell2mat(rawNumericColumns(:, 4));
Uncertainty = cell2mat(rawNumericColumns(:, 5));
Duration = cell2mat(rawNumericColumns(:, 6));
Uncertainty1 = cell2mat(rawNumericColumns(:, 7));
ReqTime = cell2mat(rawNumericColumns(:, 8));
ReqDur = rawCellColumns(:, 3);
StimType = rawCellColumns(:, 4);
PairIndex = cell2mat(rawNumericColumns(:, 9));


%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp me rawNumericColumns rawCellColumns R;

%% Cut before Responses' table
finish=find(strcmp(Code,'Response'));
Time=Time(1:finish)/1e4;
Code=Code(1:finish);
Duration=Duration(1:finish)/1e4;

%% Reference Time to the first scanner trigger
start=find(strcmp(Code,'start'));
s=find(strcmp(EventType,'Pulse'));
%s=find(strcmp(Code,'1')); %use when the pulses are not explicit
if(s(1)>start)
    Time=Time-Time(s(1));
else
    fprintf("Skaner ruszył przed instrukcją!")
    return;
end

%select conditions below then rerun the script

all_names=unique(Code); %review and select events accordingly

names{1}='b_adapt';
[onsets{1},codes{1}]=select_onsets('b'); %select onsets by all_names id
durations{1}=select_durations('b');
[onsets{1},durations{1}]=events2block(onsets{1},durations{1},codes{1},1); %concat and filter events

names{2}='b_mix';
[onsets{2},codes{2}]=select_onsets('b'); %select onsets by all_names id
durations{2}=select_durations('b');
[onsets{2},durations{2}]=events2block(onsets{2},durations{2},codes{2},2); %concat and filter events

names{3}='c_adapt';
[onsets{3},codes{3}]=select_onsets('c');
durations{3}=select_durations('c');
[onsets{3},durations{3}]=events2block(onsets{3},durations{3},codes{3},2); %concat and filter events

names{4}='rest';
[onsets{4},codes{4}]=select_onsets('ISI');
durations{4}=select_durations('ISI');
%[onsets{3},durations{3}]=events2block(onsets{3},durations{3},codes{3},2); %concat and filter events

save(fullfile(folder,name),'names','onsets','durations')

%some functions

function [bonsets,bdurations]=events2block(onsets,durations,codes,filter)
%filter 0-off, 1-congruent, 2-mix
block_last=find([diff(onsets)>3;true]); %define min block gap 
block_first=find([true;diff(onsets)>3]);
bonsets=onsets(block_first);
bdurations=onsets(block_last)+durations(block_last)-bonsets;

if filter>0
    mix=zeros(size(bonsets,1),1);
    for i=1:size(bonsets,1)
        mix(i)=size(unique(codes(block_first(i):block_last(i))),1);
    end
end
    
switch filter
    case 1
        bonsets(mix>2)=[];  %define max mixed items
        bdurations(mix>2)=[];
    case 2
        bonsets(mix<=2)=[];
        bdurations(mix<=2)=[];
    otherwise
end
end

function [onsets,codes]=select_onsets(names)
    global Time Code
    %codes=strcmpM(Code,names);
    codes=strncmp(Code,names,length(names));
    onsets=Time(codes);
    codes=Code(codes);
end

function durations=select_durations(names)
    global Duration Code
    %durations=Duration(strcmpM(Code,names));
    durations=Duration(strncmp(Code,names,length(names)));
end

function ids=strcmpM(s1,s2)
    ids=zeros(size(s1));
    for i=1:size(s2,1)
        ids=or(ids,strcmp(s1,s2(i)));
    end
end
    