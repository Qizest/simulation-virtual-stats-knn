%% plot_compare_adaptive.m
% 比较原始全局 k 与自适应 k（自适应窗口）的性能
% 输出每个 tau0 的改善情况和选择的 k*

clear; clc;
cases = case_parameters();
for i = 1:length(cases)
    fprintf('%2d: %s\n', i, cases(i).name);
end
idx = input('请输入案例编号: ');
cfg = cases(idx);

% 加载原始结果
base_file = sprintf('result_%s.mat', cfg.name);
load(base_file, 'res');
v_true = res.v_true;
v_knn_global = res.v_knn_mean;

% 加载自适应结果
adapt_file = sprintf('result_%s_adaptive_k.mat', cfg.name);
load(adapt_file, 'res');
v_knn_adapt = res.v_knn_mean;
k_star_mean = res.k_star_mean;   % 每个 tau0 的平均 k

tau = cfg.tau0_vec;

% 计算MSE
mse_global = mean((v_knn_global - v_true).^2);
mse_adapt = mean((v_knn_adapt - v_true).^2);
improve = (mse_global - mse_adapt)/mse_global*100;

% ========== 输出每个 tau0 的改善情况 ==========
fprintf('\n====== 各 τ₀ 改善情况 ======\n');
fprintf('τ₀\t原始 SqErr\t自适应 SqErr\t改善(%%)\t平均 k*\n');
for i = 1:length(tau)
    sqerr_orig = (v_knn_global(i) - v_true(i))^2;
    sqerr_adapt = (v_knn_adapt(i) - v_true(i))^2;
    if sqerr_orig > 1e-12
        imp_local = (sqerr_orig - sqerr_adapt) / sqerr_orig * 100;
    else
        imp_local = 0;
    end
    fprintf('%.1f\t%.6f\t%.6f\t%.2f\t\t%.1f\n', ...
        tau(i), sqerr_orig, sqerr_adapt, imp_local, k_star_mean(i));
end
fprintf('\n总体 MSE 改善: %.2f%%\n', improve);

% 绘图
figure('Position',[100 100 1200 800]);

% 子图1：估计曲线
subplot(2,2,1);
plot(tau, v_true, 'k-', 'LineWidth',2); hold on;
plot(tau, v_knn_global, 'b--', 'LineWidth',1.5);
plot(tau, v_knn_adapt, 'r:', 'LineWidth',1.5);
xlabel('\tau_0'); ylabel('Virtual Waiting Time');
legend('True','Global k*','Adaptive k*','Location','best');
title(sprintf('估计对比: %s (n=%d)', cfg.name, cfg.n));
grid on;

% 子图2：各点EMSE
subplot(2,2,2);
emse_global_pt = (v_knn_global - v_true).^2;
emse_adapt_pt = (v_knn_adapt - v_true).^2;
bar_width = 0.35;
x_pos = 1:length(tau);
bar(x_pos-bar_width/2, emse_global_pt, bar_width, 'FaceColor',[0 0.4470 0.7410]); hold on;
bar(x_pos+bar_width/2, emse_adapt_pt, bar_width, 'FaceColor',[0.8500 0.3250 0.0980]);
xlabel('\tau_0'); ylabel('EMSE');
legend('Global','Adaptive','Location','best');
set(gca,'XTick',x_pos,'XTickLabel',tau);
title('每个 τ₀ 的 EMSE');
grid on;

% 子图3：自适应 k* 曲线
subplot(2,2,3);
plot(tau, k_star_mean, 'g-o', 'LineWidth',1.5, 'MarkerSize',6);
xlabel('\tau_0'); ylabel('平均 k*');
title('自适应 k* 在每个 τ₀ 的平均值');
grid on;

% 子图4：总体MSE对比
subplot(2,2,4);
bar([mse_global, mse_adapt]);
set(gca,'XTickLabel',{'Global','Adaptive'});
ylabel('总体 MSE');
title(sprintf('改善 %.2f%%', improve));
grid on;

saveas(gcf, sprintf('compare_adaptive_%s.png', cfg.name));
fprintf('✅ 图片已保存: compare_adaptive_%s.png\n', cfg.name);