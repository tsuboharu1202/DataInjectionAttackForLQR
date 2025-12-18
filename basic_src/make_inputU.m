function U = make_inputU(p,T)
% MakeInputU  Generate a p-by-T input matrix that is (attemptedly) persistently exciting.
%   U = MakeInputU(p,T) returns U \in R^{p x T}.
%   各チャネルごとに "PRBS(±1) + multisine(複数正弦) + 小さな白色雑音" を混ぜ合わせ、
%   さらに直交行列でミキシングすることでチャネル間の相関を下げる。
%   その後、ブロックHankel行列 H_s(U) の行ランクが ps になる（s次のPE）かを
%   簡易チェックし、満たさなければ数回リトライする。
%
%   使い方:
%       U = MakeInputU(2, 500);   % p=2, T=500 の入力行列
%
%   備考:
%       - 厳密なPE判定ではなく、実用的なランクチェック（rank(H_s(U))=ps）を行う。
%       - s の選び方は L=T-s+1 ≥ ps を満たす上限から安全側に設定。

    arguments
        p (1,1) {mustBeInteger, mustBePositive}   % 入力の次元
        T (1,1) {mustBeInteger, mustBePositive}   % サンプル数（時間長）
    end

    % ---- s の上限: L = T - s + 1 ≥ p*s がPEの必要条件 -> s ≤ floor((T+1)/(p+1)) ----
    s_max_feasible = floor((T+1)/(p+1));
    if s_max_feasible < 2
        % T が短すぎる場合は PE チェックは諦め、1回生成して返す
        U = local_generate_once(p,T);
        U = local_postscale(U);
        return
    end
    s = min(5, s_max_feasible);   % s は大きすぎても L が小さくなって rank が落ちやすいので上限を5程度に
    L = T - s + 1;                % Hankel の列数

    maxTries = 10;   % ランクが足りないときのリトライ回数
    tol = 1e-6;      % rank() のしきい値

    for attempt = 1:maxTries
        % --- 生Uの生成：各チャネルに multisine + PRBS + noise を混ぜる ---
        U = local_generate_once(p,T);

        % --- 直交混合でチャネル間の相関を下げる（空間的な励起度を上げる）---
        M = orth(randn(p));   % p×p 直交（列正規直交基底）
        U = M * U;

        % --- 振幅の整形（実験システムへの安全のため振幅を抑える等） ---
        U = local_postscale(U);

        % --- ブロックHankel H_s(U) を作って行ランク = p*s をチェック ---
        H = zeros(p*s, L);
        for k = 1:s
            H((k-1)*p+1:k*p, :) = U(:, k:(k+L-1));  % 各ブロックは p×L
        end
        rH = rank(H, tol);

        if rH == p*s
            % フル行ランク → 実用上 s 次のPEが達成できたとみなす
            return
        end
        % 失敗なら再生成（attempt を進める）
    end

    % ここに到達したらランク達成できず。とはいえ、生成自体は問題ないので返す。
    % fprintf('MakeInputU: PE rank not achieved after %d tries (r=%d, target=%d)\n', maxTries, rH, p*s);
end

% ===== ローカル関数群 =====
function U = local_generate_once(p,T)
    % 1回分のU生成：各チャネル i で multisine + PRBS + noise を合成
    rng('shuffle');        % 毎回違う系列に
    t = (0:T-1);
    U = zeros(p,T);
    for i = 1:p
        % --- multisine（複数周波数の正弦波） ---
        K = 3;                              % 重ねる正弦の数（必要に応じて調整）
        phases = 2*pi*rand(1,K);            % ランダム位相
        maxf = max(2, floor(T/8));          % 高すぎる周波数/ナイキスト近傍を避ける簡易策
        freqs = randi([1 maxf], 1, K);      % 周波数インデックス
        ms = zeros(1,T);
        for j = 1:K
            ms = ms + sin(2*pi*freqs(j)*t/T + phases(j));
        end

        % --- PRBS（±1の擬似ランダム2値列） ---
        prbs = sign(randn(1,T));

        % --- 小さな白色雑音（帯域埋め & ランク上げの保険）---
        noise = 0.1*randn(1,T);

        % --- 合成 & 標準化（ゼロ平均・単位分散）---
        u = ms + prbs + noise;
        u = u - mean(u);
        sd = std(u);
        if sd > 1e-12, u = u/sd; end

        U(i,:) = u;
    end
end

function U = local_postscale(U)
    % 全体スケーリング（装置への入力安全や数値安定のために振幅を抑える）
    U = 0.5 * U;  % 必要に応じてスケールを調整
end
