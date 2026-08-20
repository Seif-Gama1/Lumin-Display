#ifndef MAPSTREAMITEM_H
#define MAPSTREAMITEM_H

#include <QQuickItem>
#include <QSGSimpleTextureNode>

class MapStreamItem : public QQuickItem {
    Q_OBJECT
    Q_PROPERTY(QRectF sourceCrop READ sourceCrop WRITE setSourceCrop NOTIFY sourceCropChanged)
    Q_PROPERTY(QString typedMemName READ typedMemName WRITE setTypedMemName NOTIFY typedMemNameChanged)
    QML_ELEMENT

public:
    explicit MapStreamItem(QQuickItem *parent = nullptr);
    ~MapStreamItem();

    QRectF sourceCrop() const { return m_sourceCrop; }
    void setSourceCrop(const QRectF &r);

    QString typedMemName() const { return m_typedMemName; }
    void setTypedMemName(const QString &name);

signals:
    void sourceCropChanged();
    void typedMemNameChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;

private:
    void mapTypedMemory();

    QRectF m_sourceCrop = QRectF(0, 0, 1, 1);
    QString m_typedMemName = "ivi_map_fb";
    void *m_ptr = nullptr;
    size_t m_size = 0;
    int m_fd = -1;
    uint32_t m_lastFrame = 0;

    struct Header {
        volatile uint32_t frameNumber;
        volatile uint32_t width;
        volatile uint32_t height;
        volatile uint32_t stride;
    };
};

#endif
