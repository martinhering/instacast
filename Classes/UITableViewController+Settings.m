//
//  UITableViewController+Settings.m
//  Instacast
//
//  Created by Martin Hering on 22.06.13.
//
//

#import "UITableViewController+Settings.h"

@implementation UITableViewController (Settings)

- (UITableViewCell*) standardCellWithClass:(Class)cellClass
{
    NSString *StandardCellIdentifier = NSStringFromClass(cellClass);
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:StandardCellIdentifier];
    if (cell == nil) {
        cell = [[cellClass alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:StandardCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    cell.backgroundColor = ICGroupCellBackgroundColor;
    cell.selectedBackgroundView.backgroundColor = ICGroupCellSelectedBackgroundColor;
    cell.textLabel.textColor = ICTextColor;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.imageView.image = nil;
    
    return cell;
}

- (UITableViewCell*) standardCell
{
    return [self standardCellWithClass:[UITableViewCell class]];
}

- (UITableViewCell*) switchCell
{
    static NSString *SliderCellIdentifier = @"SwitchCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:SliderCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SliderCellIdentifier];
        cell.accessoryView = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 77, 26)];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    cell.backgroundColor = ICGroupCellBackgroundColor;
    cell.textLabel.textColor = ICTextColor;
    
    UISwitch* control = (UISwitch*)cell.accessoryView;
    NSArray* actions = [control actionsForTarget:self forControlEvent:UIControlEventValueChanged];
    for(NSString* action in actions) {
        [control removeTarget:self action:NSSelectorFromString(action) forControlEvents:UIControlEventValueChanged];
    }
    
    return cell;
}

- (UITableViewCell*) textInputCell
{
    static NSString *TextInputCellIdentifier = @"TextInputCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TextInputCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextInputCellIdentifier];
        UITextField* textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 170, 26)];
        textField.textAlignment = NSTextAlignmentRight;
        cell.accessoryView = textField;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.backgroundColor = ICGroupCellBackgroundColor;
    cell.textLabel.textColor = ICTextColor;
    ((UITextField*)cell.accessoryView).text = nil;
    return cell;
}

- (UITableViewCell*) detailCell
{
    static NSString *DetailCellIdentifier = @"DetailCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:DetailCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DetailCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    cell.backgroundColor = ICGroupCellBackgroundColor;
    cell.selectedBackgroundView.backgroundColor = ICGroupCellSelectedBackgroundColor;
    cell.textLabel.textColor = ICTextColor;
    cell.detailTextLabel.textColor = ICMutedTextColor;
    
    return cell;
}

- (UITableViewCell*) resetCell
{
    static NSString *ResetCellIdentifier = @"ResetCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ResetCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ResetCellIdentifier];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    cell.backgroundColor = ICGroupCellBackgroundColor;
    cell.selectedBackgroundView.backgroundColor = ICGroupCellSelectedBackgroundColor;
    cell.textLabel.textColor = [UIColor redColor];
    return cell;
}

- (UITableViewCell*) buttonCell
{
    static NSString *ButtonCellIdentifier = @"ButtonCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ButtonCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ButtonCellIdentifier];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    cell.textLabel.textColor = self.view.tintColor;
    cell.backgroundColor = ICGroupCellBackgroundColor;
    cell.selectedBackgroundView.backgroundColor = ICGroupCellSelectedBackgroundColor;
    
    return cell;
}

- (UITableViewCell*) textCell
{
    static NSString *TextCellIdentifier = @"TextCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:TextCellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextCellIdentifier];
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    cell.backgroundColor = ICGroupCellBackgroundColor;
    cell.selectedBackgroundView.backgroundColor = ICGroupCellSelectedBackgroundColor;
    cell.textLabel.textColor = ICTextColor;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.numberOfLines = 10;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (CGFloat) heightForTextCellUsingText:(NSString*)text
{
    NSAttributedString* attributedTitle = [[NSAttributedString alloc] initWithString:text attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:15] }];
    
    CGFloat w = CGRectGetWidth(self.tableView.frame)-30;
    CGSize textLabelSize = [attributedTitle boundingRectWithSize:CGSizeMake(w, 500) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    IC_SIZE_INTEGRAL(textLabelSize);

    return textLabelSize.height+20;
}
@end
