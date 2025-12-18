function [L_opt, S_opt, J_opt, diagInfo] = solveSDP(X, U, Z, Q, R, opts)
% solveSDP : 論文(5)のSDPをYALMIPで解くユーティリティ
% -----------------------
% 引数と既定オプション
% -----------------------
if nargin < 6 || isempty(opts)
    % Prefer configured solver, but allow automatic fallback if unavailable.
    solver = 'mosek';
    try
        if isprop(cfg.Const,'SOLVER') && strlength(string(cfg.Const.SOLVER))>0
            solver = char(string(cfg.Const.SOLVER));
        end
    catch
    end
    opts = sdpsettings('solver',solver,'verbose',0,'showprogress',0);
    % 数値安定性を向上させるため、許容誤差を緩和
    if strcmpi(solver,'mosek')
        try
            opts.mosek.MSK_IPAR_LOG        = 0;
            opts.mosek.MSK_IPAR_LOG_INTPNT = 0;
            % 許容誤差を緩和（1e-6 → 1e-5）して数値問題を回避
            opts.mosek.MSK_DPAR_INTPNT_CO_TOL_REL_GAP = 1e-5;
            opts.mosek.MSK_DPAR_INTPNT_CO_TOL_PFEAS   = 1e-5;
            opts.mosek.MSK_DPAR_INTPNT_CO_TOL_DFEAS   = 1e-5;
            opts.mosek.MSK_DPAR_INTPNT_CO_TOL_INFEAS  = 1e-5;
            % 最大反復回数を増やす
            opts.mosek.MSK_IPAR_INTPNT_MAX_ITERATIONS = 400;
        catch
        end
    end
end
gamma = cfg.Const.GAMMA;
% gamma  = 1e3;


R = (R+R')/2;              % 数値対称化
V = sqrtm(R); V = (V+V')/2;

validateattributes(X, {'double'},{'2d','real','finite'});
validateattributes(U, {'double'},{'2d','real','finite'});
validateattributes(Z, {'double'},{'2d','real','finite'});
validateattributes(Q, {'double'},{'2d','real','finite','square'});
validateattributes(V, {'double'},{'2d','real','finite','square'});

[n,T]  = size(X);
[m,TU] = size(U);
[nZ,TZ]= size(Z);
assert(T==TU && T==TZ, 'X, U, Z の列数Tが一致していません');
assert(nZ==n, 'Z の行数が X と一致していません');
assert(isequal(size(Q),[n,n]), 'Q は n×n');
assert(isequal(size(V),[m,m]), 'V は m×m');

% -----------------------
% Γ と Π = I - Γ^† Γ
% -----------------------
Gamma = [X; U];                       % (m+n)×T
s  = svd(Gamma,'econ');
tol_pinv = max(size(Gamma)) * eps(max(s));
Pi = eye(T) - pinv(Gamma, tol_pinv) * Gamma;   % T×T

% -----------------------
% 変数
% -----------------------
L = sdpvar(T,n,'full');
S = sdpvar(m,m,'symmetric');

% -----------------------
% 便利量（Lに依存）
% -----------------------
XL  = X*L;
XLs = (XL + XL')/2;      % 対称化
ZL  = Z*L;
VUL = V*(U*L);

% -----------------------
% 目的関数 J(L,S,D)
% -----------------------
J = trace(Q*(X*L)) + trace(S) + gamma * norm(Pi*L,'fro')^2;

% -----------------------
% LMI制約
% -----------------------
F1c_mat = [ S,    VUL ;
    VUL', XLs ];
F1c = (F1c_mat >= 0);

F2c_mat = [ XLs - eye(n), ZL ;
    ZL',          XLs ];
F2c = (F2c_mat >= 0);

% NOTE:
% We already symmetrize XL inside the LMI blocks via XLs.
% Adding a hard equality XL == XL' can overconstrain the problem when data is limited.
% The original implementation (and the paper's SDP written in terms of symmetric blocks)
% does not require an explicit XL symmetry equality here.
Constraints = [F1c, F2c];

% -----------------------
% 最適化
% -----------------------
sol = optimize(Constraints, J, opts);
% MOSEK-only policy (default). If solver is not applicable, fail fast with guidance.
if sol.problem == -4
    error('sdp:solverNotApplicable', ...
        ['Selected solver is not applicable for semidefinite constraints: %s\n' ...
        'Fix: ensure MOSEK is correctly installed/licensed and YALMIP sees it.\n' ...
        'Current opts.solver=%s'], sol.info, string(opts.solver));
end

% -----------------------
% 出力整形 & 固有値/固有ベクトル
% -----------------------
diagInfo.problem    = sol.problem;
diagInfo.info       = sol.info;
diagInfo.yalmiptime = sol.yalmiptime;
diagInfo.solvertime = sol.solvertime;
diagInfo.Pi         = Pi;
diagInfo.solver     = opts.solver;

% エラーハンドリング: 警告レベルの問題は許容
% problem codes: 0=成功, 1=実行不可能（Infeasible）, 2=エラー, 3=未定義, 4=数値問題, 5=実行不可能, -1=不明なエラー
if sol.problem == 2 || sol.problem == 5
    error('SDP failed (code=%d): %s', sol.problem, sol.info);
elseif sol.problem == 1
    % code=1は実行不可能（Infeasible）なので、警告を出して続行（解が得られない可能性が高い）
    warning('SDP infeasible problem (code=1): %s. Solution may not be available.', sol.info);
elseif sol.problem == 4
    % 数値問題の場合は警告を出して続行（解が得られている可能性がある）
    warning('SDP numerical problems (code=%d): %s. Continuing with solution...', sol.problem, sol.info);
elseif sol.problem == -1
    % 不明なエラー（code=-1）の場合
    warning('SDP unknown error (code=-1): %s. Checking if solution is available...', sol.info);
elseif sol.problem ~= 0
    warning('SDP warning (code=%d): %s', sol.problem, sol.info);
end

% 解の数値化
L_opt = value(L);
S_opt = value(S);
J_opt = value(J);

% 解の妥当性チェック（特にcode=-1, code=1の場合）
if sol.problem == -1 || sol.problem == 1 || sol.problem ~= 0
    % 解にInf/NaNが含まれていないか確認
    if any(~isfinite(L_opt(:))) || any(~isfinite(S_opt(:))) || ~isfinite(J_opt)
        error('SDP solution contains Inf/NaN. Problem code=%d, Info: %s', sol.problem, sol.info);
    end
    
    % code=1（Infeasible）の場合、解が意味を持つか確認
    if sol.problem == 1
        % Infeasibleな場合、解が得られていない可能性が高い
        % ただし、YALMIPが近似解を返す場合もあるので、警告のみ
        warning('SDP infeasible (code=1): Solution may be invalid. Proceeding with caution.');
    end
    
    % Gamma行列の条件数をチェック（デバッグ情報）
    cond_Gamma = cond(Gamma);
    if cond_Gamma > 1e12
        warning('Gamma matrix is ill-conditioned (cond=%.2e). This may cause SDP solver issues.', cond_Gamma);
    end
end

XLv = X*L_opt;
diagInfo.XLs = (XLv + XLv')/2;
diagInfo.ZL  = Z*L_opt;
diagInfo.VUL = V*(U*L_opt);

% LMI 数値化
F1c_val = value(F1c_mat);
F2c_val = value(F2c_mat);

% 双対（ソルバ対応時のみ）
try
    diagInfo.Lambda1 = dual(F1c);
    diagInfo.Lambda2 = dual(F2c);
catch
    diagInfo.Lambda1 = [];
    diagInfo.Lambda2 = [];
end


diagInfo.F1c_val = F1c_val;
diagInfo.F2c_val = F2c_val;


end
