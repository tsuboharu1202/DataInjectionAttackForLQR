% resume_from_checkpoint.m - チェックポイントから実験を再開
% 
% 使用方法:
%   resume_from_checkpoint('checkpoint_20251218_150609.mat')
%   または
%   resume_from_checkpoint()  % 最新のチェックポイントを自動検出
%
% MATLAB Onlineでセッションが切れた場合などに使用

function resume_from_checkpoint(checkpoint_file)
    if nargin < 1 || isempty(checkpoint_file)
        % 最新のチェックポイントを自動検出
        result_dir = fullfile(fileparts(mfilename('fullpath')), 'Result');
        checkpoint_files = dir(fullfile(result_dir, 'checkpoint_*.mat'));
        if isempty(checkpoint_files)
            error('チェックポイントファイルが見つかりません。');
        end
        [~, idx] = max([checkpoint_files.datenum]);
        checkpoint_file = fullfile(result_dir, checkpoint_files(idx).name);
        fprintf('最新のチェックポイントを検出: %s\n', checkpoint_files(idx).name);
    end
    
    % フルパスに変換
    if ~contains(checkpoint_file, filesep)
        result_dir = fullfile(fileparts(mfilename('fullpath')), 'Result');
        checkpoint_file = fullfile(result_dir, checkpoint_file);
    end
    
    if ~exist(checkpoint_file, 'file')
        error('チェックポイントファイルが見つかりません: %s', checkpoint_file);
    end
    
    fprintf('チェックポイントを読み込み中: %s\n', checkpoint_file);
    load(checkpoint_file);
    
    % 必要な変数が存在するか確認
    required_vars = {'all_results', 'total_conditions', 'timestamp', ...
                     'PARAM_ATTACKER_UPPERLIMIT', 'PARAM_SAMPLE_COUNT', ...
                     'PARAM_SYSTEM_DIM', 'NUM_TRIALS', 'ATTACK_METHOD', ...
                     'SAVE_TRIAL_DATA_TO_FILE', 'EXPERIMENT_DIR'};
    
    missing_vars = {};
    for i = 1:length(required_vars)
        if ~exist(required_vars{i}, 'var')
            missing_vars{end+1} = required_vars{i};
        end
    end
    
    if ~isempty(missing_vars)
        warning('以下の変数がチェックポイントに含まれていません: %s', ...
                strjoin(missing_vars, ', '));
    end
    
    % 進捗を表示
    completed = 0;
    if exist('all_results', 'var')
        if iscell(all_results)
            completed = sum(~cellfun(@isempty, all_results));
        else
            completed = length(all_results);
        end
    end
    
    fprintf('\n=== チェックポイント情報 ===\n');
    fprintf('完了条件数: %d / %d\n', completed, total_conditions);
    fprintf('タイムスタンプ: %s\n', timestamp);
    fprintf('実験ディレクトリ: %s\n', EXPERIMENT_DIR);
    fprintf('\n実験を再開します...\n\n');
    
    % Main.mの続きを実行するため、変数をワークスペースに保持
    % 注意: このスクリプトを実行後、Main.mの該当箇所から続行する必要があります
    % または、Main.mを修正してチェックポイントから自動再開できるようにする
    
    % 変数をベースワークスペースに保存（Main.mから呼び出される場合）
    assignin('caller', 'checkpoint_loaded', true);
    assignin('caller', 'all_results', all_results);
    assignin('caller', 'total_conditions', total_conditions);
    assignin('caller', 'timestamp', timestamp);
    assignin('caller', 'EXPERIMENT_DIR', EXPERIMENT_DIR);
    
    fprintf('チェックポイントの読み込みが完了しました。\n');
    fprintf('Main.mを実行して実験を続行してください。\n');
end

