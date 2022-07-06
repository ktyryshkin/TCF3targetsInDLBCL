function modifyClustergram(clust_obj, labels_struct, options)
% %function modifyClustergram adds colourlabels below the heatmap of the
% clustergram. It also adjusts font and position of the heatmap and the
% dendrograms. When user only wants to adjust the font and potiion, without
% adding the colour labels, then the labels_struct should be empty.   
%
% Input:
%   clust_obj: the clustergram object to which the modifications are added
%   labels_struct: a struct. It can be empty, the no colour labels are
%       added. If it is not empty, it has one field for each row of
%       colour labels that are added. Each of these fields must have the
%       following fields:
%           'labels' - a vector/cell array with labels for each sample,
%               labels longer than 15 characters are truncated
%           'ordered_lbls' - a vector/cellarray with unique labels, these
%               should be ordered in the order to be displayed in the legend
%           'colours' - a vector/cell array with a colour (3d vector) for
%               each unique label, order corresponding to the ordered_lbls  
%           'description' - a vector/cell array with an optional
%               description for the colour label strip. Set as an empty
%               string ('') when no description is required. If description
%               is longer than 30characters, it is truncated.
%           'excl_from_legend' - a vector/cell array with labels from
%               ordered_lbls that should be excluded from the legend
%   options: 
%       textfont - font for the clustergram row and column labels. Default
%           is = 12pnt, mustBeInRange(6,24)
%       img_textfont - font for the colour label legends and description.
%           Default is = 9pnt, mustBeInRange(6,11)
%       italicizeRowLabels - italicize row lables of the clustergram (e.g.
%           when these are gene names)
%       dendrlinewidth - Line width for the dendrograms. Default is 2
%       ischangepossize - whether the figure needs resizing, Default =
%           false. Note, resizing after the modifications will change the
%           font of the Row and Column labels. If that is not desired,
%           specify the figure size and set ischangepossize to true. 
%       newpossize  - new figure size, applied if ischangepossize is true.
%           Default = [500 360 550 450] 
%       columnLabels -  a vector/cell array with columnLabels. These MUST
%           be in the order matching the order of the samples in the colour
%           label struct (i.e. not necessarily in the order of the
%           labels passed to the clustergram function. If no ColumnLabels
%           were passed to the clustergram function, then there is no need 
%           to specify this parameter   
%       outer padding - padding on the edge of the figure. Default is .07
%           (7% of the width of the fugure) 
%       inner_padding - padding between panels in the figure. Default is .01
%            (1/7 of the outerpadding) 
% Example:
%     rng('default')
%     rowlabels = {'1', '2', '3', 'four', '5', 'the labels is too long and will be cut', '7', '8', '9', '10'};
%     collabels = {'one', 'two', 'three', 'four', 'five', 'six', 'sevens', 'eight', 'nine', 'ten'};
% 
%     cg = clustergram(rand(10,10), 'Cluster', 3, 'DisplayRatio', .1,...
%     'RowLabels', rowlabels,'ColumnLabels',collabels );
%     addTitle(cg, 'Title for the Clustergram (optional)');
%     labels_struct = struct();
%     labels_struct.label1.labels = [ones(5,1); ones(5,1)+1];
%     labels_struct.label1.colours = {.7 0 .5; 0 0.2 .7};
%     labels_struct.label1.ordered_lbls = {'1', '2'};
%     labels_struct.label1.description = {'Group'};
%     labels_struct.label2.labels(1:3) = {'ABC'}; 
%     labels_struct.label2.labels(4:7) = {'GCB'};
%     labels_struct.label2.labels(8:10) = {'LegendIsLongerthan15chars'};
%     labels_struct.label2.ordered_lbls = {'ABC', 'GCB', 'LegendIsLongerthan15chars'};
%     labels_struct.label2.colours = {.7 0 .5; 0 0.2 .7; 0 .5 .5};
%     labels_struct.label2.description = {'This is description for the second label'};
% 
%     modifyClustergram(cg, labels_struct, 'ischangepossize', true, 'columnLabels', collabels);
%     
%example 2: 
%       %not passing columnLabels to the clustergram and to
%       %modifyClustergram functions produces the same result: 
%       cg = clustergram(rand(10,10), 'Cluster', 3, 'DisplayRatio', .1,...
%           'RowLabels', rowlabels);
%       modifyClustergram(cg, labels_struct, 'ischangepossize', true);

% Author: Kathrin Tyryshkin
% Last edited: 3 June 2022
 
 
%input checking                        
    arguments
        clust_obj {mustBeClustergram(clust_obj)}
        labels_struct struct {mustBeValidStruct(labels_struct)} 
        options.textfont uint8 {mustBeGreaterThan(options.textfont, 5), mustBeLessThan(options.textfont, 25)} = 12 
        options.img_textfont uint8 {mustBeGreaterThan(options.img_textfont, 5), mustBeLessThan(options.img_textfont, 12)}= 9 
        options.italicizeRowLabels = false
        options.dendrlinewidth uint8 = 2
        options.ischangepossize logical = false
        options.newpossize(1,4) double = [500 360 550 450]
        options.columnLabels {mustBeValidLabels(options.columnLabels, clust_obj)}= {}
        options.outer_padding double {mustBeGreaterThanOrEqual(options.outer_padding, 0), mustBeLessThan(options.outer_padding, 1)} = .07 %edge of the figure
        options.inner_padding double {mustBeGreaterThanOrEqual(options.inner_padding, 0), mustBeLessThan(options.inner_padding, 1)} = .01;%1/7 of the outer padding
    end
        
    % Get figure handles that correspond to clustergram objects
    clusterfig = findall(0,'type','figure', 'Tag', 'Clustergram');
    %In case there are more than one clustergram objects, operate on the
    %first one on the list - that will be the last clustergram created.
    currClustergramIdx = 1;     
    if options.ischangepossize  %change size of the clustergram      
        %Set clustergram's new position
        set(clusterfig(currClustergramIdx),'Position', options.newpossize);
    end
    
    %make sure the input columnLabels is a cell array of strings
    options.columnLabels = convertIfNeeded(options.columnLabels);
        
    %calculate the new size/position for all the axes: heatmap, dendrograms
    %and the labels under the clustergram
    numberOfImgLabels = length(fieldnames(labels_struct));  
    %trim labels if too long, convert to text if numeric
    labels_struct = adjustTextLabels(labels_struct);
    %calculate the size needed for the text labels 
    titleAx = findall(clusterfig(currClustergramIdx),'Tag','HeatMapTitleAxes');
    clustergram_props = calcTextSize(titleAx, labels_struct, options.img_textfont);
    
    
    %% calculate the new height of all axes (panels):  
    %title axis, top axis (the top/column dendrogram), 
    %the middle axis (heatmap, side/row dendrogram and the colorbar
    %the low axis (the colour labels with legend and description
    
    %height of the image labels bar is the number of labels*height of the
    %txt legend + number of labels*space between the labels
    clustergram_props.lowPanelHeight = clustergram_props.num_legend_lbls*clustergram_props.txt_height*0.9;
    clustergram_props.topPanelHeigth = 0;    
    %Find top/column dendrorgram axis 
    dendroAxCol = findall(clusterfig(currClustergramIdx),'Tag','DendroColAxes');
    if ~isempty(dendroAxCol) && ~strcmpi(clust_obj.ShowDendrogram, 'Off')      
        p = get(dendroAxCol, 'Position');
        clustergram_props.topPanelHeigth = p(4);
    end
    %find title if exists
    titleAx = findall(clusterfig(currClustergramIdx),'Tag','HeatMapTitleAxes');
    a = findall(titleAx,'Type','text');
    clustergram_props.titleHeight = 0;
    if ~isempty(get(a, 'string'))
        e = get(a, 'extent');
        clustergram_props.titleHeight = e(4);
    end
    
    clustergram_props.midPanelHeight = max(0, 1-(clustergram_props.lowPanelHeight+options.outer_padding+options.inner_padding)-...
        (clustergram_props.topPanelHeigth) - (clustergram_props.titleHeight+options.outer_padding));
         
    %% calculate the new width of all axes (panels)
    %left panel (the left/row dendrogram with colorbar and the image lbl
    %description; mid axis (the up/col dendrogram, the heatmap, the image
    %labels); right axis (the image legends and the heatmap row labels)
    
    %Find side/row dendrogram axis 
    left_dendro_width = 0;
    dendroAxRow = findall(clusterfig(currClustergramIdx),'Tag','DendroRowAxes');
    if ~isempty(dendroAxRow) && ~strcmpi(clust_obj.ShowDendrogram, 'Off')        
        p = get(dendroAxRow, 'Position');
        left_dendro_width = p(3);
    end
    %assume the colour bar takes the same space as the left dendrogram.  
    % Can only find out its true size when it is plotted, but have to plot
    % it after the heatmap is adjusted, so that it matches the height     
    clustergram_props.leftPanelWidth = max(clustergram_props.descr_txtwidth+options.inner_padding, 2*left_dendro_width);
 
    %find the longest clustergram row label, if longer than 15 - truncate
    heatmapAx = findall(clusterfig(currClustergramIdx),'Tag','HeatMapAxes');   
    all_row_labels = get(heatmapAx, 'YTickLabel');
    x = 1:length(all_row_labels);
    x=x(cellfun(@(x) numel(x),all_row_labels)>15);
    for j=1:length(x)
        currstr = all_row_labels{x(j)};
        all_row_labels(x(j)) = {currstr(1:min(end,15))};
        disp(['Note: row label ' currstr ' is too long, truncating to 15 characters']);
    end
    if options.italicizeRowLabels
       all_row_labels = strcat('\it', all_row_labels);
    end
    set(heatmapAx, 'YTickLabel', all_row_labels);
    val=cellfun(@(x) numel(x), all_row_labels);
    longest_row_str=all_row_labels(val==max(val));
    longest_row_str = cell2mat(longest_row_str(1));
    t = text(titleAx, 0.5,0.5,longest_row_str, 'fontsize', options.textfont);
    e = get(t, 'Extent');
    maxRowLblWidth = e(3);
    delete(t);
    
    %right panel width
    clustergram_props.rightPanelWidth = max(clustergram_props.leg_txtwidth+options.inner_padding, maxRowLblWidth);
        
    clustergram_props.midPanelWidth = max(0, 1-(clustergram_props.rightPanelWidth+...
        options.outer_padding)-(clustergram_props.leftPanelWidth+options.outer_padding));
    
    %% rearrange all existing axes, to fit in image labels, remove white spaces
    %and make sure the colorbar and text labels fit into the figure space
    t = findall( clusterfig(currClustergramIdx), 'type', 'axes');
    for i=1:length(t) %shift every axis
        currPos = get(t(i), 'Position');
        if strcmp(get(t(i), 'tag'), 'DendroRowAxes')
           currPos(1) = clustergram_props.leftPanelWidth-left_dendro_width+options.outer_padding+options.inner_padding;
           currPos(2) = clustergram_props.lowPanelHeight+options.outer_padding+options.inner_padding;
           currPos(4) = clustergram_props.midPanelHeight;           
           set(get(t(i),'Children'), 'linewidth', options.dendrlinewidth);
        elseif strcmp(get(t(i), 'tag'), 'HeatMapAxes')
           currPos(1) = clustergram_props.leftPanelWidth+options.outer_padding+options.inner_padding;
           currPos(2) = clustergram_props.lowPanelHeight+options.outer_padding+options.inner_padding;
           currPos(3) = clustergram_props.midPanelWidth;
           currPos(4) = clustergram_props.midPanelHeight;
        elseif strcmp(get(t(i), 'tag'), 'DendroColAxes')
           currPos(1) = clustergram_props.leftPanelWidth+options.outer_padding+options.inner_padding;
           currPos(2) = clustergram_props.lowPanelHeight+clustergram_props.midPanelHeight+options.outer_padding+options.inner_padding;
           currPos(3) = clustergram_props.midPanelWidth;
           set(get(t(i),'Children'), 'linewidth', options.dendrlinewidth);   
        elseif strcmp(get(t(i), 'tag'), 'HeatMapTitleAxes')
           %do nothing, its position does not change
        end      
        set(t(i), 'Position',currPos);
    end
    
    %set font after resizing the heatmap, otherwise, it won't take effect
    %attempting to fix the font size so it doesn't change when figure is
    %resized - for some reason it doesn't work for the heatmap labels.
    set(heatmapAx, 'defaultAxesFontsize', options.textfont);
    set(heatmapAx, 'FontSize', options.textfont)
    %set background to white
    set(clusterfig(currClustergramIdx),'color','w');
    
   %% add the image labels, if exist
    
    if numberOfImgLabels > 0 %if there are labels to plot
        
        %set up the axis         
        img_lbl_pos = [clustergram_props.leftPanelWidth+options.outer_padding+options.inner_padding, options.outer_padding, ...
            clustergram_props.midPanelWidth, clustergram_props.lowPanelHeight];         
        legend_pos = [clustergram_props.leftPanelWidth+clustergram_props.midPanelWidth+options.outer_padding+2*options.inner_padding,...
            options.outer_padding, clustergram_props.rightPanelWidth, clustergram_props.lowPanelHeight]; 
        descr_pos = [options.outer_padding, options.outer_padding, clustergram_props.leftPanelWidth, clustergram_props.lowPanelHeight];
        img_lbl_ax = axes(clusterfig(currClustergramIdx),'Position',img_lbl_pos);
        legend_ax = axes(clusterfig(currClustergramIdx),'Position',legend_pos);
        descr_ax = axes(clusterfig(currClustergramIdx),'Position',descr_pos);
        set(img_lbl_ax, 'YDir', 'normal');
        hold(img_lbl_ax,'on');set(img_lbl_ax,'visible','off');
        hold(legend_ax,'on');set(legend_ax,'visible','off');
        hold(descr_ax,'on');set(descr_ax,'visible','off');
        
        %order the labels in the same order as the clustering
        %get the tickLabels(trim edging white spaces)
        all_col_labels = strtrim(clust_obj.ColumnLabels);
        if ~isempty(options.columnLabels) %column labels were specified            
            [~,~, order] = intersect(all_col_labels, options.columnLabels, 'stable');
        else  
            order = cell2mat(cellfun(@str2num, all_col_labels, 'UniformOutput', false));
        end
        
        %assign colormap to the image label axis
        [cmap,labels_struct] = addLblVector(labels_struct, order);
        colormap(img_lbl_ax, cmap); 
        
        fn = fieldnames(labels_struct);
        txt_h = clustergram_props.txt_height;
        cnt = 1; bar_extent = txt_h*5;
        mid = zeros(numberOfImgLabels,1);
        
        %plot legend labels first and compute the size for the images
        for i=1:numberOfImgLabels
            curr_lbl_data = labels_struct.(fn{i});
            
            % add legend   
            legends = curr_lbl_data.ordered_lbls;
            leg_col = curr_lbl_data.colorids;
            if sum(strcmpi(fieldnames(curr_lbl_data), 'excl_from_legend')) == 1
                flag = strcmp(legends, curr_lbl_data.excl_from_legend);
                legends(flag) = [];
                leg_col(flag) = [];
            end
            y_pos = zeros(length(legends),1);            
            for j=1:length(legends)
                plot(legend_ax, 0,1-(txt_h*(cnt-1))-i*txt_h/2, 'o','MarkerFaceColor',cmap(leg_col(j), :), 'MarkerEdgeColor', cmap(leg_col(j), :), 'MarkerSize', 5);
                t = text(legend_ax, 0.1,1-(txt_h*(cnt-1))-i*txt_h/2, legends(j), 'fontsize', options.img_textfont);               
                %record the y position of each text label - to calculate
                %the center of the text and the image
                p = get(t, 'Position');
                y_pos(j)= p(2);
                cnt = cnt+1;
            end
            mid(i) = (y_pos(1)+y_pos(end))/2; %middle is between the first and last legend y position
            bar_extent = min(bar_extent, (y_pos(1) - mid(i))/2); %imagesc adds 2 more points to the right and to the left of the specified points;
            text(descr_ax, 0, mid(i), curr_lbl_data.description, 'fontsize', options.img_textfont);
 
        end
        %plot this one separately, because first need to compute the extent
        for i=1:numberOfImgLabels
            curr_lbl_data = labels_struct.(fn{i});
            imagesc(img_lbl_ax, .5, [mid(i)-bar_extent mid(i)+bar_extent], curr_lbl_data.colorid_vector');%, 'CDataMapping', 'direct'
        end
        
        %cleanup the look
        %hide xlabels on the heatmap
        set(heatmapAx, 'xtick',[]);
        %adjust the axes limit
        lims = get(legend_ax, 'ylim');
        lims(1) = mid(end) - txt_h; %adjust the lowest axis point by the last legend text y position
        ylim(legend_ax, lims); ylim(img_lbl_ax, lims); ylim(descr_ax, lims);
        xlim(legend_ax, [-.1 1]);xlim(img_lbl_ax, [0 clustergram_props.num_txt_lbls]);
        hold(legend_ax,'off'); hold(img_lbl_ax,'off'); hold(descr_ax,'off');
        %axis padded
    end %end if there are labels to plot
    
    %% Add the color bar to the clustergram, 
    % must add at the end, so that MATLAB automatically positions it in the right place.
    cbButton = findall(clusterfig(currClustergramIdx),'tag','HMInsertColorbar');
    % Get callback (ClickedCallback) for the button:
    ccb = get(cbButton,'ClickedCallback');
    % Change the button state to 'on' (clicked down):
    set(cbButton,'State','on');
    % Run the callback to create the colorbar:
    ccb{1}(cbButton,[],ccb{2});
    % %modify the font of the colorbar
    cb  = findobj(clusterfig(currClustergramIdx),'Tag','HeatMapColorbar');
    set(cb,'FontSize', options.textfont);
    %shift to right by colorbar_offset to fit in the figure
    pos = get(cb, 'Position');
    pos(1) = pos(1)+ options.outer_padding;
    set(cb, 'Position', pos);

end %main function
 
 
function [cmap, data_struct] = addLblVector(data_struct, order)
%Create colour map for all the colours that were specified for the colour
%labels. The colourmap will be assigned to an axis that holds all colour
%label strips. To make sure that for each colour label a correct colour is
%selected from the colourmap, indices to the rows in the colour map are
%assigned for each colour strip in a form of vector - an index for each
%unique label.
% 
    fn = fieldnames(data_struct);
    cmap = [];   
    for i=1:length(fn)
        curr_lbl_data = data_struct.(fn{i});
        %sort by the order of the clustering
        curr_lbl_data.labels = curr_lbl_data.labels(order);
        %combine all unique colours into one colourmap        
        cmap = unique([cmap; curr_lbl_data.colours], 'stable', 'rows');
        colorid_vector = zeros(length(curr_lbl_data.labels),1);
        color_ids = zeros(length(curr_lbl_data.ordered_lbls),1);
        for j=1:length(curr_lbl_data.ordered_lbls)
            %find index in the colour map and assign it to each label
            currcol = curr_lbl_data.colours(j, :);
            [~, currindx] = ismember(currcol, cmap, 'rows');
            colorid_vector(strcmpi(curr_lbl_data.labels, curr_lbl_data.ordered_lbls(j))) = currindx;
            color_ids(j) = currindx;
        end
        data_struct.(fn{i}).colorid_vector = colorid_vector;
        data_struct.(fn{i}).colorids = color_ids;
    end

end
 
function properties = calcTextSize(ax, data_struct, fntSize)
%calculate the length and height needed for the longest legend label and for
%the longest description label. This allows to adjust the axis
%accordingly
    properties = struct();
    properties.txt_height = 0;
    properties.txt_space = 0;
    properties.leg_txtwidth = 0;
    properties.descr_txtwidth = 0;
    properties.num_legend_lbls = 0;
    properties.num_txt_lbls = 0;
    
    fn = fieldnames(data_struct);
    if ~isempty(fn)
        %pul all unique labels into one cell array
        all_leg_labels = {};
        all_txt_labels = {};
        cnt_excluded = 0;
        for i=1:length(fn)            
            all_leg_labels = [all_leg_labels; data_struct.(fn{i}).ordered_lbls'];
            %adjust if there is a newline adde to the description - take
            %the longest piece.
            descr = cell2mat(data_struct.(fn{i}).description);
            ind = strfind(descr, newline);
            if ~isempty(ind)
                str1 = descr(1:ind(1));
                str2 = descr(ind(1):end);
                if length(str1) >= length(str2)
                    all_txt_labels = [all_txt_labels; str1];
                else
                    all_txt_labels = [all_txt_labels; str2];
                end
            else
                all_txt_labels = [all_txt_labels; data_struct.(fn{i}).description];
            end
            %count how many legends are excluded
            if sum(strcmpi(fieldnames(data_struct.(fn{i})), 'excl_from_legend')) == 1
                cnt_excluded = cnt_excluded+length(data_struct.(fn{i}).excl_from_legend);
            end
        end
        properties.num_txt_lbls = length(data_struct.(fn{i}).labels); %number of columns
        properties.num_legend_lbls = length(all_leg_labels)-cnt_excluded;
        %find the longest legend label
        val=cellfun(@(x) numel(x),all_leg_labels);
        longest_leg_str=all_leg_labels(val==max(val));
        longest_leg_str = cell2mat(longest_leg_str(1));
        t = text(ax, 0.5,0.5,longest_leg_str, 'fontsize', fntSize);
        e = get(t, 'Extent');
        properties.txt_height = e(4);
        properties.txt_space = e(4)/2;
        properties.leg_txtwidth = e(3);
        delete(t);
        
        %find the longest description label
        %don't count itilicized or bold symbols
        tmp = strrep(all_txt_labels, '{\it', '');
        val=cellfun(@(x) numel(x),tmp);
        longest_txt_str=tmp(val==max(val));
        %if there is more than one of the same maximum length, take the first one
        t = text(ax, 0.5,0.5,longest_txt_str, 'fontsize', fntSize);
        e = get(t, 'Extent');
        properties.descr_txtwidth = e(3);
        delete(t);
    end
end
 
function data_struct = adjustTextLabels(data_struct)
%adjusts lengths of the labels and description to the maximum length
% If labels and ordered_lbl fields are numeric, it
%converts them to cell array of characters - to be compatible with the code
    fn = fieldnames(data_struct);
    for i=1:length(fn)
        %if ordered_lbls is numeric vector, convert to string
        data_struct.(fn{i}).ordered_lbls = convertIfNeeded(data_struct.(fn{i}).ordered_lbls);
        %if labels is numeric vector, convert to string
        data_struct.(fn{i}).labels = convertIfNeeded(data_struct.(fn{i}).labels);
        % check the max length of the labels, if longer than 15chars- truncate
        x = 1:length(data_struct.(fn{i}).ordered_lbls);
        x=x(cellfun(@(x) numel(x),data_struct.(fn{i}).ordered_lbls)>15);
        for j=1:length(x)%for all labels longer than 15 chr - truncate
            currstr = data_struct.(fn{i}).ordered_lbls{x(j)};
            flag = strcmpi(data_struct.(fn{i}).labels, currstr);
            data_struct.(fn{i}).ordered_lbls{x(j)}= currstr(1:15);
            data_struct.(fn{i}).labels(flag) = {currstr(1:15)};
            disp(['Note: label ' currstr ' is too long, truncating to 15 characters']);
        end
        % check the max length of the description, if longer than 30 - truncate,
        %add new line at a space closest to 15 chars
        x = 1:length(data_struct.(fn{i}).description);
        x=x(cellfun(@(x) numel(x),data_struct.(fn{i}).description)>15);
        for j=1:length(x)
            currstr = data_struct.(fn{i}).description{x(j)};  
            %don't count itilicized or bold symbols
            tmp = strrep(currstr, '{\it', '');
            %find first space after 15th character and replace it with the new line
            ind = strfind(tmp(15:end), ' ');
            if ~isempty(ind)
                ind = ind(1)+14;
                last = min(ind*2, length(currstr));
                currstr = [currstr(1:ind-1) newline() currstr(ind+1:last)];
            end            
            data_struct.(fn{i}).description{x(j)}= currstr;
        end
    end
end
function mustBeValidStruct(data_struct)
% Custom validation function
%check that the input struct has all the required fields with matching
%lengths and values as required by the function (see modifyClustergram
%function description). 
 
    % Check for MATLAB version, need (2020a) or higher
    if verLessThan('matlab','9.8.0')
        error('modifyClustergram requires MATLAB 2020a or higher');
    end
    %check the input is a struct
    if ~isstruct(data_struct)
        error('The input must be a struct');
    end
    %check the input struct has all the required fields
    fn = fieldnames(data_struct);
    for i=1:length(fn)
        curr_label = data_struct.(fn{i});
        if sum(strcmpi(fieldnames(curr_label), 'labels')) ~= 1 || ...
                sum(strcmpi(fieldnames(curr_label), 'colours')) ~= 1 || ...
                sum(strcmpi(fieldnames(curr_label), 'ordered_lbls')) ~= 1 || ...
                sum(strcmpi(fieldnames(curr_label), 'description')) ~= 1
            error(['The input must be a struct with 4 fields' ...
                '(labels, colours, ordered_lbls, description) '...
                'for each layer of colour labels, label# ' num2str(i)]);
        end
        %check the colours and ordered_lbls have the same
        %length and it is equal to the number of unique labels.
        if size(curr_label.colours,1)~=length(curr_label.ordered_lbls) || ...
                length(curr_label.description)~=1 || ...
                size(curr_label.colours,1)~=length(unique(curr_label.labels))
            error(['Incorrect length of the input fields, label# ' num2str(i)]);
        end
        %check that unique labels are the same as the ordered_lbls
        %if ordered_lbls is numeric vector, convert to string
        curr_label.ordered_lbls = convertIfNeeded(curr_label.ordered_lbls);
        %if labels is numeric vector, convert to string
        curr_label.labels = convertIfNeeded(curr_label.labels);
        [~,indA] = intersect(curr_label.ordered_lbls, unique(curr_label.labels));
        if length(indA) ~= length(curr_label.ordered_lbls)
            error(['Mismatch between labels and the ordered_lbls. ' ...
                'The labels field consists of labels for each sample, ' ...
                'the ordered_lbls consists of unique label categories, ordered '...
                'in the order to be displayed in the legend, label# ' num2str(i)]);
        end
        %check if colors is a numeric matrix Nx3
        if ~isnumeric(curr_label.colours) || size(curr_label.colours, 2) ~= 3
            error(['The colour vector must be a numeric matrix nx3,' ... 
                ' where n is the number of categories in a label, label# ' num2str(i)]);
        end
        %check that description is a cell array.
        if ~iscell(curr_label.description)
            error('The discription must be a cell array.');
        end
    end
end
 
function mustBeClustergram(clust_obj)
%check the input is a clustergram
    if ~isa(clust_obj, 'clustergram')
        error(['The input must be a clustergram, instead it is a ' class(clust_obj)]);
    end
end
 
function mustBeValidLabels(columnLabels, clust_obj)
%check that the columnLabels are the same as in the clustergram
    if isempty(columnLabels)
        %when Column (or Row) labels are not passed to the clustergram function,
        %it generates numeric labels (1,2,...n)
        order = cell2mat(cellfun(@str2num, clust_obj.ColumnLabels, 'UniformOutput', false));
        %if labels are not numeric, the order is an empty string, that means
        %the ColumnLabels were passed to the clustergram, so options.columnLabels can't be empty 
        if isempty(order)
            error(['User must provide optional parameter for same columnLabels. '...
                'These must be the same as the ones passed to the clustergram function.']);
        end
    else
        columnLabels = convertIfNeeded(columnLabels);
        if ~isequal(sort(columnLabels), sort(strtrim(clust_obj.ColumnLabels)))
            error('The columnLabels in options do not match the columnLabels in the clustergram');
        end
    end
end

function vect_out = convertIfNeeded(vect_in)
%converts a numeric vector to a cell array of strings/chars
    vect_out = vect_in;
    if isnumeric(vect_out)
        if iscolumn(vect_out) %must be row in order to be converted
            vect_out = vect_out';
        end
        vect_out = strsplit(num2str(vect_out));
    end
end
        