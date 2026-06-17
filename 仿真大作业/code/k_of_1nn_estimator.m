function v_hat = k_of_1nn_estimator(data, tau0, k)
% 对每个 replication 取 1-NN，再按距离排序取前 k 个平均

    n = length(data);
    if n == 0
        v_hat = NaN; 
        return;
    end
    
    nearest = zeros(n, 2);   % 第1列: 距离, 第2列: Y 值
    
    for j = 1:n
        t_j = data{j}(:,1);
        y_j = data{j}(:,2);
        [dist, idx] = min(abs(t_j - tau0));
        nearest(j,1) = dist;
        nearest(j,2) = y_j(idx);
    end
    
    % 关键一步：按距离从小到大排序
    [~, sort_idx] = sort(nearest(:,1));
    
    k = min(k, n);
    v_hat = mean(nearest(sort_idx(1:k), 2));
end