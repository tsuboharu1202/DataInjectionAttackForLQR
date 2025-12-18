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

% 衝突回避
clear cfg
clear classes
rehash toolboxcache

% 動作確認（コメントアウト可）
% assert(exist('cfg.Const','class')==8, 'cfg.Const not visible. Check paths.');
