#include "fpga_drv.h"
//编写 platform 对应device的驱动
struct device_container dev_container;



unsigned int get_first_unused_fpga_device_idx(struct device_container *p_dev_container) {
    unsigned int idx;
    for (idx = 0; idx < MAX_DEVICE_NUMS; ++idx) {
        if (p_dev_container->dev_list[idx] == NULL) {
            break;
        }
    }
    return idx;
}

// platform_drvier和platform_device匹配时会调用此函数
// Issue the basic operation to fpga, such as initialization

static int fpga_dev_probe(struct platform_device *pdev)
{
    struct fpga_dev *my_dev;
     struct device_container *p_dev_container = &dev_container;
    unsigned int idx;
    int ret;
    struct fpga_device *fdev;

    // devm_xxx的函数会自动回收内存
    my_dev = devm_kzalloc(&pdev->dev, sizeof(*gl), GFP_KERNEL);
    
    platform_set_drvdata(pdev, my_dev);
}

// platform_device从系统移除时会调用此函数
static int fpga_dev_remove(struct platform_device *pdev)
{
    struct xxx_dev *my_dev = platform_get_drvdata(pdev);
    ...
}

static struct platform_driver fpga_driver = {
    .driver = {
        .name = "fpgadrv",              // device_driver中只定义了名字
        .owner = THIS_MODULE,
    },
    .probe = fpga_dev_probe,
    .remove = fpga_dev_remove,
};
// 注册platform driver到platform bus
module_platform_driver(xxx_driver);
