
export const checkRole = (rolesPermitidos = []) => {
  return (req, res, next) => {
    const userRole = req.user?.rol;

    if (!userRole) {
      return res.status(403).json({ message: "Rol no especificado en el token" });
    }

    if (!rolesPermitidos.includes(userRole)) {
      return res.status(403).json({ message: "Acceso denegado: rol no autorizado" });
    }

    next();
  };
};
