% startup.m  (ForCommunication 直下)
projroot = fileparts(mfilename('fullpath'));

% 親だけ通す（+cfg 自体は通さない）
addpath(projroot);
addpath(genpath(fullfile(projroot,'basic_src')));
% resourcesフォルダが存在する場合のみ追加
if exist(fullfile(projroot,'resources'), 'dir')
    addpath(genpath(fullfile(projroot,'resources')));
end
addpath(genpath(fullfile(projroot,'scripts')));
addpath(genpath(fullfile(projroot,'lqr_src')));  % もしパッケージ化しているなら '+com' は不要

% MATLAB Online用の外部ツールボックスのパス設定
% MATLAB Driveのパスを確認（MATLAB Onlineの場合）
if exist('/MATLAB Drive', 'dir')
    % YALMIPのパス追加
    yalmip_path = '/MATLAB Drive/IshiiLab/YALMIP';
    if exist(yalmip_path, 'dir')
        addpath(genpath(yalmip_path));
    end
    
    % MOSEKのパス追加（Linux版）
    mosek_path = '/MATLAB Drive/IshiiLab/mosek_linux/mosek/11.0/toolbox/r2019b';
    if exist(mosek_path, 'dir')
        addpath(genpath(mosek_path));
    end
    
    % MOSEKライセンスファイルの自動コピー
    % MATLAB Onlineでは/home/matlab/mosek/mosek.licが必要
    lic_source = '/MATLAB Drive/IshiiLab/mosek_linux/mosek.lic';
    lic_target_dir = '/home/matlab/mosek';
    lic_target = fullfile(lic_target_dir, 'mosek.lic');
    
    if exist(lic_source, 'file')
        % ターゲットディレクトリが存在しない場合は作成
        if ~exist(lic_target_dir, 'dir')
            try
                mkdir(lic_target_dir);
            catch
                % ディレクトリ作成に失敗した場合はスキップ
            end
        end
        
        % ライセンスファイルをコピー（存在しない場合、または更新が必要な場合）
        if ~exist(lic_target, 'file')
            try
                copyfile(lic_source, lic_target);
            catch
                % コピーに失敗した場合は警告のみ（環境変数に依存）
            end
        end
        
        % 環境変数も設定（フォールバック用）
        setenv('MOSEKLM_LICENSE_FILE', lic_source);
    end
end

% 衝突回避
clear cfg
clear classes
% MATLAB Onlineではrehash toolboxcacheが失敗する可能性があるため、try-catchで囲む
try
    rehash toolboxcache
catch
    % MATLAB Onlineではスキップ
end

% 動作確認（コメントアウト可）
% assert(exist('cfg.Const','class')==8, 'cfg.Const not visible. Check paths.');
