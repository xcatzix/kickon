-- Author: xcatzix  
-- mailto: 3949745980@qq.com  
-- Using it in paying money  

# 对plasma-desktop中的kickoff相关代码进行如下修改:
-- 1. 将各软件应用归类放入到Applications这个位置, 去掉总标签Applications ,各软件分类标签横向  
      平铺在底部的power and session那一列, 去掉分类名称, 仅使用图标标注;  
-- 2. 将Places标签放到All Applications标签去; 将All Applications标签放到lost & Found标签后面.  
-- 3. kickoff放在panel上时,用户打开kickoff,窗口默认在屏幕中间.  
-- 4. 在窗口类title的位置,即搜索框左边增加panel(layout.js的功能, panel的实现).  
-- 5. places横屏排版需要调整好,有目录树结构.去掉Computer,History和Frequently Used一列.  
-- 6. 外观美学需达到我的图片内的美学(示例:*.png).   
-- 7. 将kickoff改名为kickon, 注册为org.kde.plasma.kickon.  
-- 8. Search输入框只要图标大小的文本窗口,保留现有的功能即不需要鼠标点击即可输入; 当有文字输入  
      时,在原位自动展开悬浮输入框,不改变其他子项位置,不改变高度,只需适当增加长度即可. 新增:当  
      点击到Places时, 需要能够检索文档. 或者在检索文本框直接输入:a xxx是检索Applications; 输入  
      p XXX是检索Places;  
-- 9. 去掉plasma-desktop中其他应用代码,仅保留kickoff相关依赖代码.  
-- 10. 先写到这里....  


-- 注: org.kde.plasma.kickon-fix4为AI修改版,未达到要求.--