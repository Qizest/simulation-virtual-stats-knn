function v_hat = knn_point_estimator(data, tau0, k)
    all_t = [];
    all_y = [];
    for j = 1:length(data)
        if ~isempty(data{j})
            all_t = [all_t; data{j}(:,1)];
            all_y = [all_y; data{j}(:,2)];
        end
    end
    if isempty(all_t)
        v_hat = NaN; return;
    end
    [~, idx] = sort(abs(all_t - tau0));
    k = min(k, length(idx));   % 边界自动缩小 k
    nearest_y = all_y(idx(1:k));
    v_hat = mean(nearest_y);
end