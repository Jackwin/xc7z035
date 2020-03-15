
//platform 对应device的驱动
struct fpga_dev {
    ...
};

// platform_drvier和platform_device匹配时会调用此函数
static int fpga_dev_probe(struct platform_device *pdev)
{
    struct xxx_dev *my_dev;
    // devm_xxx的函数会自动回收内存
    my_dev = devm_kzalloc(&pdev->dev, sizeof(*gl), GFP_KERNEL);
    ...
    platform_set_drvdata(pdev, my_dev);
}

// platform_device从系统移除时会调用此函数
static int fpga_dev_remove(struct platform_device *pdev)
{
    struct xxx_dev *my_dev = platform_get_drvdata(pdev);
    ...
}

static struct platform_driver xxx_driver = {
    .driver = {
        .name = "xxx",              // device_driver中只定义了名字
        .owner = THIS_MODULE,
    },
    .probe = fpga_dev_probe,
    .remove = fpga_dev_remove,
};
// 注册platform driver到platform bus
module_platform_driver(xxx_driver);
