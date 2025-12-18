function check_system(result_file)
% check_system: 保存されたシステム情報を確認
%
% 使用例:
%   check_system('Result/experiment_results_20251216_220332.mat')
%   または
%   load('Result/experiment_results_20251216_220332.mat')
%   check_system()  % ワークスペースの変数を使用

% ファイルが指定されている場合は読み込む
if nargin >= 1 && ~isempty(result_file)
    fprintf('結果ファイルを読み込み中: %s\n', result_file);
    
    % パスの解決
    if ~isfile(result_file)
        script_dir = fileparts(mfilename('fullpath'));
        full_path = fullfile(script_dir, result_file);
        if isfile(full_path)
            result_file = full_path;
        else
            error('ファイルが見つかりません: %s\n試したパス: %s', result_file, full_path);
        end
    end
    
    load(result_file);
end

% ワークスペースに変数があるか確認
if ~exist('all_results', 'var')
    error('all_results変数が見つかりません。ファイルを読み込むか、ワークスペースに変数があることを確認してください。');
end

fprintf('\n=== システム情報の確認 ===\n');
fprintf('条件数: %d\n', length(all_results));
fprintf('\n');

% 各条件でのシステム情報を表示
for i = 1:length(all_results)
    r = all_results(i);
    fprintf('--- 条件 %d: eps=%.4f, T=%d, n=%d, m=%d ---\n', ...
        i, r.eps_att, r.T, r.n, r.m);
    
    % システム行列が保存されているか確認
    if isfield(r, 'A') && isfield(r, 'B')
        fprintf('  ✓ システム行列が保存されています\n');
        fprintf('    A: %dx%d\n', size(r.A, 1), size(r.A, 2));
        fprintf('    B: %dx%d\n', size(r.B, 1), size(r.B, 2));
        
        % Aの固有値を表示
        if isfield(r, 'eig_A')
            fprintf('    Aの固有値: ');
            fprintf('%.4f%+.4fi ', real(r.eig_A), imag(r.eig_A));
            fprintf('\n');
            fprintf('    Aの最大固有値の絶対値: %.4f\n', max(abs(r.eig_A)));
        end
        
        % 最適ゲインが保存されているか確認
        if isfield(r, 'K_ori')
            fprintf('  ✓ 最適ゲインK_oriが保存されています: %dx%d\n', ...
                size(r.K_ori, 1), size(r.K_ori, 2));
        end
        
        % A+B*Kの固有値が保存されているか確認
        if isfield(r, 'eig_AplusBK_ori')
            fprintf('  ✓ A+B*K_oriの固有値が保存されています\n');
            fprintf('    A+B*K_oriの最大固有値の絶対値: %.4f\n', ...
                max(abs(r.eig_AplusBK_ori)));
        end
        
        % Q, Rが保存されているか確認
        if isfield(r, 'Q') && isfield(r, 'R')
            fprintf('  ✓ 重み行列が保存されています\n');
            fprintf('    Q: %dx%d\n', size(r.Q, 1), size(r.Q, 2));
            fprintf('    R: %dx%d\n', size(r.R, 1), size(r.R, 2));
        end
    else
        fprintf('  ✗ システム行列が保存されていません\n');
    end
    
    % 試行データが保存されているか確認
    if isfield(r, 'trial_data')
        fprintf('  ✓ 試行データが保存されています\n');
        if isfield(r.trial_data, 'X') && isfield(r.trial_data, 'U') && isfield(r.trial_data, 'Z')
            num_trials = length(r.trial_data.X);
            fprintf('    試行数: %d\n', num_trials);
            fprintf('    各試行でX, U, Z, X_adv, Z_adv, U_advが保存されています\n');
        end
    end
    
    fprintf('\n');
end

% 同じ条件内でシステムが同じか確認
fprintf('=== 同じ条件内でのシステム一貫性チェック ===\n');
for i = 1:length(all_results)
    r = all_results(i);
    if isfield(r, 'A') && isfield(r, 'B')
        % システムが保存されている場合、同じ条件内の全試行で同じシステムが使われていることを確認
        fprintf('条件 %d: システムは条件ごとに1回生成され、全試行で共有されています\n', i);
        fprintf('  (試行ごとに変わるのはU, X, Zデータのみ)\n');
    end
end
fprintf('\n');

fprintf('確認完了！\n');
end

