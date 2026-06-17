%% plot_compare_reflection.m
% 对比原始 kNN 与边界反射法 kNN

clear; clc;
cases = case_parameters();
for i = 1:length(cases)
    fprintf('%2d: %s\n', i, cases(i).name);
end
idx = input('请输入案例编号: ');
if isempty(idx) || idx < 1 || idx > length(cases)
    error('无效序号');
end
cfg = cases(idx);

% 加载原始结果
base_file = sprintf('result_%s.mat', cfg.name);
if ~exist(base_file, 'file')
    error('未找到原始结果文件: %s', base_file);
end
load(base_file, 'res');
v_true = res.v_true;
v_knn_orig = res.v_knn_mean;
k_orig_mean = mean(res.k_star_knn_all);
k_orig_std = std(res.k_star_knn_all);

% 加载反射法结果
ref_file = sprintf('result_%s_reflection.mat', cfg.name);
if ~exist(ref_file, 'file')
    error('未找到反射法结果文件: %s', ref_file);
end
load(ref_file, 'res');
v_knn_ref = res.v_knn_mean;
k_ref_mean = res.k_star_knn_mean;
k_ref_std = res.k_star_knn_std;

tau = cfg.tau0_vec;

% 计算误差
sqerr_orig = (v_knn_orig - v_true).^2;
sqerr_ref = (v_knn_ref - v_true).^2;

mse_orig = mean(sqerr_orig);
mse_ref = mean(sqerr_ref);
improvement = (mse_orig - mse_ref) / mse_orig * 100;

% 输出 k* 信息
fprintf('\n====== k* 对比 ======\n');
fprintf('原始方法: 平均 k* = %.2f (std = %.2f)\n', k_orig_mean, k_orig_std);
fprintf('反射法:   平均 k* = %.2f (std = %.2f)\n', k_ref_mean, k_ref_std);

% 输出各 tau0 改善情况
fprintf('\n====== 各 τ₀ 改善情况 ======\n');
fprintf('τ₀\t原始 SqErr\t反射法 SqErr\t改善(%%)\n');
for i = 1:length(tau)
    if sqerr_orig(i) > 1e-12
        imp = (sqerr_orig(i) - sqerr_ref(i)) / sqerr_orig(i) * 100;
    else
        imp = 0;
    end
    fprintf('%.1f\t%.6f\t%.6f\t%.2f\n', tau(i), sqerr_orig(i), sqerr_ref(i), imp);
end
fprintf('\n总体 MSE 改善: %.2f%%\n', improvement);

% 绘图
figure('Position', [100, 100, 1200, 500]);

subplot(1,2,1);
plot(tau, v_true, 'k-', 'LineWidth', 2.5); hold on;
plot(tau, v_knn_orig, 'b--', 'LineWidth', 1.8);
plot(tau, v_knn_ref, 'g-.', 'LineWidth', 1.8);
xlabel('\tau_0'); ylabel('Virtual Waiting Time');
legend('True', sprintf('Original (k=%.1f)', k_orig_mean), ...
       sprintf('Reflection (k=%.1f)', k_ref_mean), 'Location', 'best');
title(sprintf('原始 kNN vs 反射法: %s (n=%d)', cfg.name, cfg.n));
grid on;

subplot(1,2,2);
bar(tau, [sqerr_orig(:), sqerr_ref(:)], 'grouped');
xlabel('\tau_0'); ylabel('Squared Error');
legend(sprintf('Original (MSE=%.4e)', mse_orig), ...
       sprintf('Reflection (MSE=%.4e)', mse_ref), 'Location', 'best');
title(sprintf('EMSE per τ₀ (改善 %.2f%%)', improvement));
grid on;

saveas(gcf, sprintf('compare_reflection_%s.png', cfg.name));
fprintf('✅ 图片已保存: compare_reflection_%s.png\n', cfg.name);