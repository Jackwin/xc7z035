// 完成platform_device的注册和注销
// 定义platform device，platform device的注册，定义platform driver（fpga_drv）,注册platform driver

static struct platform_device *xxx_pdev;

static int __init xxx_dev_init(void)
{
    int ret;
    // 注意此名字和platform_driver中的名字一致
    xxx_pdev = platform_device_alloc("xxx", -1);
    if (!xxx_pdev)
        return -ENOMEM;
    // 注册platform_device到系统
    ret = platform_device_add(xxx_pdev);
    if (ret) {
        platform_device_put(xxx_pdev);
        return ret;
    }

    return 0;
}
module_init(xxx_dev_init);

static void __exit xxx_dev_exit(void)
{
    // 从系统中注销platform_device
    platform_device_unregister(xxx_pdev);
}
module_exit(xxx_dev_exit);
