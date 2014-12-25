//
//  FileListUploadCell.m
//  Coding_iOS
//
//  Created by Ease on 14/12/24.
//  Copyright (c) 2014年 Coding. All rights reserved.
//

#import "FileListUploadCell.h"
#import "Coding_FileManager.h"
#import "ASProgressPopUpView.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>

@interface FileListUploadCell ()<ASProgressPopUpViewDelegate>
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIButton *reDoButton, *cancelButton;

@property (strong, nonatomic) ASProgressPopUpView *progressView;
@property (strong, nonatomic) NSProgress *progress;
@end


@implementation FileListUploadCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithHexString:@"0xececec"];
        if (!_iconView) {
            _iconView = [[UIImageView alloc] init];
            _iconView.contentMode = UIViewContentModeScaleAspectFill;
            _iconView.clipsToBounds = YES;
            [self.contentView addSubview:_iconView];
        }
        if (!_nameLabel) {
            _nameLabel = [[UILabel alloc] init];
            _nameLabel.textColor = [UIColor colorWithHexString:@"0x222222"];
            _nameLabel.font = [UIFont systemFontOfSize:16];
            [self.contentView addSubview:_nameLabel];
        }
        if (!_reDoButton) {
            _reDoButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_reDoButton setImage:[UIImage imageNamed:@"btn_file_reDo"] forState:UIControlStateNormal];
            [_reDoButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:_reDoButton];
        }
        if (!_cancelButton) {
            _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [_cancelButton setImage:[UIImage imageNamed:@"btn_file_cancel"] forState:UIControlStateNormal];
            [_cancelButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
            [self.contentView addSubview:_cancelButton];
        }
        if (!_progressView) {
            _progressView = [[ASProgressPopUpView alloc] initWithFrame:CGRectMake(kPaddingLeftWidth, [FileListUploadCell cellHeight]-2.5, kScreen_Width- kPaddingLeftWidth, 2.0)];
            
            _progressView.popUpViewCornerRadius = 12.0;
            _progressView.delegate = self;
            _progressView.font = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:12];
            [_progressView setTrackTintColor:[UIColor colorWithHexString:@"0xd5d5d5"]];
            _progressView.popUpViewAnimatedColors = @[[UIColor colorWithHexString:@"0x3abd79"]];
            [self.progressView hidePopUpViewAnimated:NO];
            [self.contentView addSubview:self.progressView];
        }
        
        [_iconView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(32, 32));
            make.centerY.equalTo(@[self.contentView, _nameLabel, _reDoButton, _cancelButton]);
            make.left.equalTo(self.contentView.mas_left).with.offset(17);
        }];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_iconView.mas_right).with.offset(17);
            make.height.mas_equalTo(20);
            make.width.greaterThanOrEqualTo(@120);
        }];
        [_reDoButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(22, 22));
            make.left.mas_greaterThanOrEqualTo(_nameLabel.mas_right);
        }];
        [_cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(22, 22));
            make.left.equalTo(_reDoButton.mas_right).with.offset(20);
            make.right.equalTo(self.contentView.mas_right).with.offset(-20);
        }];
    }
    return self;
}
- (void)setProgress:(NSProgress *)progress{
    _progress = progress;
    __weak typeof(self) weakSelf = self;
    if (_progress) {
        [_progressView setTrackTintColor:[UIColor colorWithHexString:@"0xd5d5d5"]];

        [[RACObserve(self, progress.fractionCompleted) takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(NSNumber *fractionCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updatePregress:fractionCompleted.doubleValue];
            });
        }];
    }else{
        [_progressView setTrackTintColor:[UIColor colorWithHexString:@"0xff4632"]];
        [_progressView setProgress:0];
    }
}

- (void)updatePregress:(double)fractionCompleted{
    //更新进度
    self.progressView.progress = fractionCompleted;
    if (ABS(fractionCompleted - 1.0) < 0.0001) {
        //已完成
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self && self.doneUploadBlock) {
                self.doneUploadBlock();
            }
        });
    }
}

- (void)buttonClicked:(id)sender{
    if (sender == _reDoButton && _reUploadBlock) {
        _reUploadBlock(_fileName);
    }else if (sender == _cancelButton && _cancelUploadBlock){
        _cancelUploadBlock(_fileName);
    }
}

- (void)setFileName:(NSString *)fileName{
    _fileName = fileName;
    if (!_fileName || _fileName.length <= 0) {
        return;
    }
    Coding_FileManager *manager = [Coding_FileManager sharedManager];

    NSURL *fileUrl = [manager diskUploadUrlForFile:_fileName];
    [_iconView sd_setImageWithURL:fileUrl placeholderImage:nil];
    
    NSArray *fileInfos = [_fileName componentsSeparatedByString:@"|||"];
    _nameLabel.text = [fileInfos lastObject];
    
    Coding_UploadTask *cUploadTask = [manager cUploadTaskForFile:_fileName];
    if (cUploadTask) {//有上传任务
        if (cUploadTask.task && cUploadTask.task.state == NSURLSessionTaskStateRunning) {
            _reDoButton.hidden = YES;
        }else{
            [manager removeCUploadTaskForFile:_fileName hasError:YES];
            _reDoButton.hidden = NO;
        }
        self.progress = cUploadTask.progress;
    }else{
        _reDoButton.hidden = NO;
        self.progress = nil;
    }
}


+ (CGFloat)cellHeight{
    return 49.0;
}
#pragma mark ASProgressPopUpViewDelegate
- (void)progressViewWillDisplayPopUpView:(ASProgressPopUpView *)progressView;
{
    [self.superview bringSubviewToFront:self];
}
@end