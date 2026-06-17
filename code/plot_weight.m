%% plot_compare_weighted.m
% 对比原始 kNN 与加权 kNN：估计曲线 + EMSE 直方图
% 需要已存在 result_案例名.mat 和 result_案例名_weighted_knn.mat

clear; clc;

% 选择案例
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
if ~isfield(res, 'v_knn_mean')
    error('原始结果中缺少 v_knn_mean 字段');
end
v_true = res.v_true;
v_knn_orig = res.v_knn_mean;
k_orig_mean = mean(res.k_star_knn_all);  % 原始平均 k*

% 加载加权结果
weighted_file = sprintf('result_%s_weighted_knn.mat', cfg.name);
if ~exist(weighted_file, 'file')
    error('未找到加权结果文件: %s', weighted_file);
end
load(weighted_file, 'res');
if ~isfield(res, 'v_knn_mean')
    error('加权结果中缺少 v_knn_mean 字段');
end
v_knn_weighted = res.v_knn_mean;
k_weighted_mean = mean(res.k_star_knn_all);  % 加权平均 k*

% 计算每个 τ₀ 的平方误差
sqerr_orig = (v_knn_orig - v_true).^2;
sqerr_weighted = (v_knn_weighted - v_true).^2;

% 整体 MSE
mse_orig = mean(sqerr_orig);
mse_weighted = mean(sqerr_weighted);
improvement = (mse_orig - mse_weighted) / mse_orig * 100;

% 创建图形（两个子图）
tau = cfg.tau0_vec;
figure('Position', [100, 100, 1200, 500]);

% ---- 子图1：估计曲线对比 ----
subplot(1,2,1);
plot(tau, v_true, 'k-', 'LineWidth', 2.5); hold on;
plot(tau, v_knn_orig, 'b--', 'LineWidth', 1.8);
plot(tau, v_knn_weighted, 'r-.', 'LineWidth', 1.8);
xlabel('\tau_0', 'FontSize', 12);
ylabel('Virtual Waiting Time', 'FontSize', 12);
legend('True', sprintf('Original kNN (k=%.1f)', k_orig_mean), ...
       sprintf('Weighted kNN (k=%.1f)', k_weighted_mean), ...
       'Location', 'best');
title(sprintf('Estimation Curves: %s (n=%d)', cfg.name, cfg.n));
grid on; box on;

% ---- 子图2：各点平方误差直方图 ----
subplot(1,2,2);
bar(tau, [sqerr_orig(:), sqerr_weighted(:)], 'grouped');
xlabel('\tau_0', 'FontSize', 12);
ylabel('Squared Error', 'FontSize', 12);
legend(sprintf('Original (MSE=%.4e)', mse_orig), ...
       sprintf('Weighted (MSE=%.4e)', mse_weighted), ...
       'Location', 'best');
title(sprintf('EMSE per τ₀ (改善 %.2f%%)', improvement));
grid on; box on;

% 保存图片
saveas(gcf, sprintf('compare_weighted_%s.png', cfg.name));
fprintf('图片已保存为 compare_weighted_%s.png\n', cfg.name);

% 输出统计信息
fprintf('\n====== 性能对比 ======\n');
fprintf('原始 kNN MSE:   %.6f\n', mse_orig);
fprintf('加权 kNN MSE:   %.6f\n', mse_weighted);
fprintf('改善百分比:     %.2f%%\n', improvement);
fprintf('原始平均 k*:    %.1f\n', k_orig_mean);
fprintf('加权平均 k*:    %.1f\n', k_weighted_mean);

% 输出每个 tau0 的改善情况
fprintf('\n====== 各 τ₀ 改善情况 ======\n');
fprintf('τ₀\t原始 SqErr\t加权 SqErr\t改善(%%)\n');
for i = 1:length(tau)
    imp_local = (sqerr_orig(i) - sqerr_weighted(i)) / sqerr_orig(i) * 100;
    fprintf('%.1f\t%.6f\t%.6f\t%.2f\n', tau(i), sqerr_orig(i), sqerr_weighted(i), imp_local);
end