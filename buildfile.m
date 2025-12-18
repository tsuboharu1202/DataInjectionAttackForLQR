function plan = buildfile
plan = buildplan(localfunctions);
plan.DefaultTasks = "check";
end

function checkTask(~)
disp("** check を開始");
assert(exist('+sdp/solveSDP.m','file')==2, 'solveSDPが見つかりません');
disp("** check の完了");
end

function demoTask(~)
run fullfile('scripts','run_demo.m');
end
