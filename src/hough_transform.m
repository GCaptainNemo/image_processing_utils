Img  = imread('../resources/综合题图像.jpg');
origin_Img = Img;
% 1. 用低帽变换做波谷检测器
se = strel('rectangle',[3 3]);%选取结构元素为3*3的矩形
Ibot = imbothat(Img, se); % 低帽变换
figure(1);
subplot(131); imshow(Ibot); title('低帽变换后的图像');
hist = zeros(1, 256);
totalnum = numel(Ibot);

for i = 1:totalnum 
    hist(Ibot(i) + 1) = hist(Ibot(i) + 1) + 1;
end
num = 0;
for i = 256:-1:1
    num = num + hist(i);
    if num / totalnum > 0.01
        graythresh = i - 1;
        break
    end
end
% 2. 进行统计灰度二值化
bw = im2bw(Ibot, graythresh / 255);
subplot(132); imshow(bw); title('取灰度前1%点的灰度作为阈值进行二值化');

% 3. Hough变换提取直线
[H,T,R] = hough(bw);%计算二值图像的标准霍夫变换，H为霍夫变换矩阵，I,R为计算霍夫变换的角度和半径值
P = houghpeaks(H, 3);%提取3个极值点
lines=houghlines(bw,T,R,P);%提取线段
subplot(133); imshow(bw); title('对二值图像进行hough变换'); hold on;
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');%画出线段
    plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');%起点
    plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');%终点
end

% 4. Hough变换直线端点作为种子点，区域生长法
stackx = [lines(1).point2(1), lines(1).point1(1)];
stacky = [lines(1).point2(2), lines(1).point1(2)];
[row, column] = size(bw);
mask = zeros([row, column]);
mask(lines(1).point2(2), lines(1).point1(1)) = 1;
mask(lines(1).point2(2), lines(1).point1(1)) = 1;

% 对hough变换提取的直线端点进行区域生长，找到最大连通区域
mask = region_grow(mask, bw, stackx, stacky);  


B = ones(3, 3);
% after_erode = imerode(mask, B);
after_dilate_mask = imdilate(mask, B);
after_erode_mask = imerode(after_dilate_mask, B);


figure(2);
subplot(121); imshow(mask); title('以hough变换得到的端点作为种子点，区域生长获得掩模');
subplot(122); imshow(after_dilate_mask); title('膨胀后的掩模');


Img(find(after_dilate_mask, 1)) = 0;
figure(3); 
subplot(121); imshow(Img); title('Image'); 
subplot(122); imshow(after_dilate_mask); title('after dilate');

% 5. 提取出直线掩模后，进行修补
% 更简单的priority 周围少mask的先补
while ~isempty(find(after_dilate_mask, 1))
    [row_list, column_list] = find(after_dilate_mask, 1);
    max_num = 0; next_index = 0;
    for i = 1:length(row_list)
        num = 0;
        for window_row = -3: 3
            for window_column = -3: 3
                if row_list(i) + window_row > 0 && column_list(i) + window_column > 0
                    if after_dilate_mask(row_list(i) + window_row, column_list(i) + window_column) == 0
                        num = num + 1;
                    end
                end
            end
        end
        if num > max_num
            max_num = num;
            next_index = i;
        end
    end
    grayscale = 0;
    grayscale_lst = [];
    for window_row = -3: 3
        for window_column = -3: 3
            if row_list(next_index) + window_row > 0 && column_list(next_index) + window_column > 0 
                if after_dilate_mask(row_list(next_index) + window_row, ...
                    column_list(next_index) + window_column) == 0
                    grayscale_lst = [grayscale_lst, Img(row_list(next_index) + window_row, ...
                    column_list(next_index) + window_column)];
                end
            end
        end
    end
    after_dilate_mask(row_list(next_index), column_list(next_index)) = 0;
%     Img(row_list(next_index), column_list(next_index)) = median(grayscale_lst);
    Img(row_list(next_index), column_list(next_index)) = sum(grayscale_lst) / numel(grayscale_lst);
    
end

figure(4); 
subplot(121); imshow(origin_Img); title('原始图像');
subplot(122); imshow(Img); title('在膨胀掩模处进行中值滤波处理后图像');


% 区域生长法函数
function mask = region_grow(mask, bw, stackx, stacky)
[row, column] = size(bw);
while ~isempty(stackx) 
    origin_point = [stackx(end), stacky(end)];
    origin_grayscale = bw(origin_point(2), origin_point(1));
    stackx = stackx(1:end - 1);   % 出栈
    stacky = stacky(1:end - 1);
    for i = -5:5
        if 1 <= origin_point(1) + i && origin_point(1) + i <=  column
            for j = -5:5
                if 1 <= origin_point(2) + j && origin_point(2) + j <=  row 
                    if abs(bw(origin_point(2) + j, origin_point(1) + i) - ...
                        origin_grayscale) < 1 && ...
                        mask(origin_point(2) + j, origin_point(1) + i) ~= 1 ...
                        stackx = [stackx, origin_point(1) + i];  % 入栈
                        stacky = [stacky, origin_point(2) + j];
                        mask(origin_point(2) + j, origin_point(1) + i) = 1;
                    end
                end
            end
        end
    end
end
end
