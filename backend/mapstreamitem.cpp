#include "mapstreamitem.h"
#include <QSGTexture>
#include <QQuickWindow>
#include <QImage>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

MapStreamItem::MapStreamItem(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
    mapTypedMemory();
}

MapStreamItem::~MapStreamItem() {
    if (m_ptr && m_ptr != MAP_FAILED) munmap(m_ptr, m_size);
    if (m_fd >= 0) close(m_fd);
}

void MapStreamItem::setSourceCrop(const QRectF &r) {
    if (m_sourceCrop != r) {
        m_sourceCrop = r;
        emit sourceCropChanged();
        update();
    }
}

void MapStreamItem::setTypedMemName(const QString &name) {
    if (m_typedMemName != name) {
        m_typedMemName = name;
        if (m_ptr) { munmap(m_ptr, m_size); m_ptr = nullptr; }
        if (m_fd >= 0) { close(m_fd); m_fd = -1; }
        mapTypedMemory();
        emit typedMemNameChanged();
        update();
    }
}

void MapStreamItem::mapTypedMemory() {
    m_fd = posix_typed_mem_open(m_typedMemName.toUtf8().constData(),
                                O_RDONLY, POSIX_TYPED_MEM_ALLOCATE);
    if (m_fd < 0) {
        qWarning("MapStreamItem: posix_typed_mem_open(%s) failed: %d",
                 qPrintable(m_typedMemName), errno);
        return;
    }

    // Query size from typed memory object
    struct stat st;
    if (fstat(m_fd, &st) == 0) {
        m_size = st.st_size;
    } else {
        m_size = 0x400000; // fallback
    }

    m_ptr = mmap(nullptr, m_size, PROT_READ, MAP_SHARED, m_fd, 0);
    if (m_ptr == MAP_FAILED) {
        qWarning("MapStreamItem: mmap failed");
        m_ptr = nullptr;
        close(m_fd);
        m_fd = -1;
    }
}

QSGNode *MapStreamItem::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
    if (!m_ptr || m_ptr == MAP_FAILED) return oldNode;

    auto *hdr = static_cast<Header*>(m_ptr);
    if (hdr->frameNumber == m_lastFrame) {
        return oldNode; // nothing new
    }
    m_lastFrame = hdr->frameNumber;

    uint32_t w = hdr->width;
    uint32_t h = hdr->height;
    uint32_t stride = hdr->stride;
    if (w == 0 || h == 0 || w > 1920 || h > 1080) return oldNode;

    const uchar *pixels = static_cast<const uchar*>(m_ptr) + sizeof(Header);
    QImage frame(const_cast<uchar*>(pixels), w, h, stride, QImage::Format_RGBA8888);

    QSGTexture *tex = window()->createTextureFromImage(frame);
    if (!tex) return oldNode;

    QSGSimpleTextureNode *node = static_cast<QSGSimpleTextureNode*>(oldNode);
    if (!node) {
        node = new QSGSimpleTextureNode();
        node->setFiltering(QSGTexture::Linear);
    }

    node->setTexture(tex);
    node->setRect(boundingRect());

    // Apply normalized crop to source pixels
    QRectF src(m_sourceCrop.x() * w,
               m_sourceCrop.y() * h,
               m_sourceCrop.width() * w,
               m_sourceCrop.height() * h);
    node->setSourceRect(src);

    return node;
}
